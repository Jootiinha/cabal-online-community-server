package def

import (
	"cabal-online-community-server/share/network"
	"cabal-online-community-server/share/rpc"
)

var ServerConfig = &Config{}
var ServerSettings = &Settings{}
var NetworkManager = &network.Network{}
var PacketHandler = &network.PacketHandler{}
var RPCHandler = &rpc.Client{}
