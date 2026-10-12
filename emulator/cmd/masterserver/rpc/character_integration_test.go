//go:build integration

package rpc

import (
	_ "github.com/go-sql-driver/mysql"
	"github.com/jmoiron/sqlx"
	"github.com/ubis/Freya/cmd/masterserver/data"
	"github.com/ubis/Freya/cmd/masterserver/database"
	"github.com/ubis/Freya/share/models/character"
	"gopkg.in/yaml.v2"
	"os"
	"testing"
)

func TestCreateCharacterPersistence(t *testing.T) {
	dsn := os.Getenv("CABAL_TEST_DSN")
	if dsn == "" {
		t.Fatal("use scripts/integration-test.sh with disposable database")
	}
	db, err := sqlx.Connect("mysql", dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	g_DatabaseManager.DBList = map[int]*database.Database{1: {DB: db}}
	contents, err := os.ReadFile("../../../data/initial_data.yml")
	if err != nil {
		t.Fatal(err)
	}
	g_DataLoader.InitialData = &data.InitialData{}
	if err := yaml.Unmarshal(contents, g_DataLoader.InitialData); err != nil {
		t.Fatal(err)
	}
	for i, percent := range []string{"100", "200"} {
		t.Setenv("CABAL_INITIAL_HP_PERCENT", percent)
		req := character.CreateReq{Server: 1, Character: character.Character{Id: int32(8 + i), Name: "LocalTest" + percent, Style: character.Style{BattleStyle: 1}}}
		var res character.CreateRes
		if err := CreateCharacter(nil, &req, &res); err != nil {
			t.Fatal(err)
		}
		var hp int
		if err := db.Get(&hp, "SELECT max_hp FROM characters WHERE id=?", req.Id); err != nil {
			t.Fatal(err)
		}
		if hp != 50*(i+1) || int(res.Character.MaxHP) != hp {
			t.Fatalf("persisted HP=%d", hp)
		}
		for _, table := range []string{"characters_equipment", "characters_inventory", "characters_skills", "characters_quickslots"} {
			var count int
			if err := db.Get(&count, "SELECT COUNT(*) FROM "+table+" WHERE id=?", req.Id); err != nil || count == 0 {
				t.Fatalf("%s: %d %v", table, count, err)
			}
		}
	}
	t.Setenv("CABAL_INITIAL_HP_PERCENT", "1001")
	var res character.CreateRes
	if err := CreateCharacter(nil, &character.CreateReq{Server: 1, Character: character.Character{Id: 10, Name: "InvalidHP", Style: character.Style{BattleStyle: 1}}}, &res); err == nil {
		t.Fatal("invalid HP accepted")
	}
	var count int
	if err := db.Get(&count, "SELECT COUNT(*) FROM characters WHERE id=10"); err != nil || count != 0 {
		t.Fatal("invalid character persisted", err)
	}
	// Force an error after the character insert to verify transaction rollback.
	t.Setenv("CABAL_INITIAL_HP_PERCENT", "100")
	db.MustExec("CREATE TRIGGER reject_inventory BEFORE INSERT ON characters_inventory FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='test rollback'")
	if err := CreateCharacter(nil, &character.CreateReq{Server: 1, Character: character.Character{Id: 11, Name: "RollbackTest", Style: character.Style{BattleStyle: 1}}}, &res); err == nil {
		t.Fatal("expected inventory error")
	}
	if err := db.Get(&count, "SELECT COUNT(*) FROM characters WHERE id=11"); err != nil || count != 0 {
		t.Fatal("transaction did not roll back", err)
	}
}
