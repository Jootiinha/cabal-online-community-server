package def

import (
	"cabal-online-community-server/cmd/loginserver/rsa"
	"cabal-online-community-server/share/models/server"
)

type Settings struct {
	server.Settings
	RSA rsa.RSA
}
