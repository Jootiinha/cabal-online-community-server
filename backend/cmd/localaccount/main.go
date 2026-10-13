// Local-only account provisioning using the same bcrypt format as AuthCheck.
package main

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"github.com/go-sql-driver/mysql"
	"golang.org/x/crypto/bcrypt"
	"os"
	"path/filepath"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
func run() error {
	if len(os.Args) != 2 {
		return fmt.Errorf("expected private credentials output path")
	}
	path := os.Args[1]
	if username, password := os.Getenv("CABAL_LOCAL_USERNAME"), os.Getenv("CABAL_LOCAL_PASSWORD"); username != "" || password != "" {
		return update(path, username, password)
	}
	if _, err := os.Stat(path); err == nil {
		return verify(path)
	}
	secret := make([]byte, 6)
	if _, err := rand.Read(secret); err != nil {
		return err
	}
	password := hex.EncodeToString(secret)
	key := make([]byte, 16)
	if _, err := rand.Read(key); err != nil {
		return err
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	cfg := mysql.NewConfig()
	cfg.User = "cabal_local"
	cfg.Passwd = os.Getenv("DB_PASSWORD")
	cfg.Net = "tcp"
	cfg.Addr = databaseAddress()
	cfg.DBName = "cabal_login"
	if cfg.Passwd == "" {
		return fmt.Errorf("DB_PASSWORD missing")
	}
	db, err := sql.Open("mysql", cfg.FormatDSN())
	if err != nil {
		return err
	}
	defer db.Close()
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	username := "localplayer"
	var count int
	if err := tx.QueryRow("SELECT COUNT(*) FROM accounts WHERE username=?", username).Scan(&count); err != nil {
		return err
	}
	if count != 0 {
		return fmt.Errorf("localplayer already exists; refusing to change password")
	}
	result, err := tx.Exec("INSERT INTO accounts (username,password,status,auth_key) VALUES (?,?,?,?)", username, string(hash), 32, hex.EncodeToString(key))
	if err != nil {
		return err
	}
	id, err := result.LastInsertId()
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0700); err != nil {
		return err
	}
	file, err := os.OpenFile(path, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0600)
	if err != nil {
		return err
	}
	err = json.NewEncoder(file).Encode(map[string]interface{}{"username": username, "password": password, "id": id})
	closeErr := file.Close()
	if err != nil || closeErr != nil {
		os.Remove(path)
		return fmt.Errorf("could not save credentials")
	}
	if err := tx.Commit(); err != nil {
		os.Remove(path)
		return err
	}
	fmt.Println("Local player account created. Credentials:", path)
	return nil
}

func update(path, username, password string) error {
	if len(username) == 0 || len(username) > 16 || len(password) < 8 || len(password) > 72 {
		return fmt.Errorf("username must be 1..16 bytes and password must be 8..72 bytes")
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("read existing credentials: %w", err)
	}
	var current struct {
		Username string `json:"username"`
		ID       int64  `json:"id"`
	}
	if err := json.Unmarshal(raw, &current); err != nil {
		return err
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	key := make([]byte, 16)
	if _, err := rand.Read(key); err != nil {
		return err
	}
	cfg := mysql.NewConfig()
	cfg.User, cfg.Passwd, cfg.Net, cfg.Addr, cfg.DBName = "cabal_local", os.Getenv("DB_PASSWORD"), "tcp", databaseAddress(), "cabal_login"
	if cfg.Passwd == "" {
		return fmt.Errorf("DB_PASSWORD missing")
	}
	db, err := sql.Open("mysql", cfg.FormatDSN())
	if err != nil {
		return err
	}
	defer db.Close()
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var duplicate int
	if err := tx.QueryRow("SELECT COUNT(*) FROM accounts WHERE username = ? AND id <> ?", username, current.ID).Scan(&duplicate); err != nil {
		return err
	}
	if duplicate != 0 {
		return fmt.Errorf("username already belongs to another account")
	}
	result, err := tx.Exec("UPDATE accounts SET username = ?, password = ?, status = ?, auth_key = ? WHERE id = ?", username, string(hash), 32, hex.EncodeToString(key), current.ID)
	if err != nil {
		return err
	}
	if changed, err := result.RowsAffected(); err != nil || changed != 1 {
		return fmt.Errorf("local account not found")
	}
	updated, err := json.MarshalIndent(map[string]interface{}{"username": username, "password": password, "id": current.ID}, "", "  ")
	if err != nil {
		return err
	}
	temp := path + ".tmp"
	if err := os.WriteFile(temp, append(updated, '\n'), 0600); err != nil {
		return err
	}
	if err := tx.Commit(); err != nil {
		os.Remove(temp)
		return err
	}
	if err := os.Rename(temp, path); err != nil {
		return fmt.Errorf("account updated but credentials file needs repair: %w", err)
	}
	fmt.Println("Local account credentials updated:", path)
	return nil
}

func verify(path string) error {
	raw, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	var credentials struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}
	if err := json.Unmarshal(raw, &credentials); err != nil {
		return err
	}
	cfg := mysql.NewConfig()
	cfg.User = "cabal_local"
	cfg.Passwd = os.Getenv("DB_PASSWORD")
	cfg.Net = "tcp"
	cfg.Addr = databaseAddress()
	cfg.DBName = "cabal_login"
	db, err := sql.Open("mysql", cfg.FormatDSN())
	if err != nil {
		return err
	}
	defer db.Close()
	var hash string
	var status int
	if err := db.QueryRow("SELECT password,status FROM accounts WHERE username=?", credentials.Username).Scan(&hash, &status); err != nil {
		return err
	}
	if status != 32 {
		return fmt.Errorf("account not in normal state")
	}
	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(credentials.Password)); err != nil {
		return err
	}
	fmt.Println("Existing account and bcrypt credentials verified:", path)
	return nil
}

func databaseAddress() string {
	if address := os.Getenv("CABAL_DB_ADDRESS"); address != "" {
		return address
	}
	return "127.0.0.1:3306"
}
