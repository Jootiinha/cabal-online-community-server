package def

import (
	"cabal-online-community-server/cmd/masterserver/data"
	"cabal-online-community-server/cmd/masterserver/database"
	"cabal-online-community-server/cmd/masterserver/server"
	"cabal-online-community-server/share/rpc"

	"github.com/jmoiron/sqlx"
)

var ServerConfig = &Config{}
var ServerSettings = &Settings{}
var RPCHandler = &rpc.Server{}
var LoginDatabase = &sqlx.DB{}
var ServerManager = &server.ServerManager{}
var DatabaseManager = &database.DatabaseManager{}
var DataLoader = &data.Loader{}
