package def

import "cabal-online-community-server/share/models/server"

type Settings struct {
	server.Settings
	ServerId  int
	ChannelId int
}
