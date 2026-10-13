package packet

import (
	"cabal-online-community-server/cmd/loginserver/def"
	"cabal-online-community-server/share/log"
	"cabal-online-community-server/share/script"
)

var g_ServerConfig = def.ServerConfig
var g_ServerSettings = def.ServerSettings
var g_PacketHandler = def.PacketHandler
var g_RPCHandler = def.RPCHandler

// Registers network packets
func RegisterPackets() {
	log.Info("Registering packets...")

	var pk = g_PacketHandler
	pk.Register(CONNECT2SVR, "Connect2Svr", Connect2Svr)
	pk.Register(VERIFYLINKS, "VerifyLinks", VerifyLinks)
	pk.Register(AUTHACCOUNT, "AuthAccount", AuthAccount)
	pk.Register(FDISCONNECT, "FDisconnect", FDisconnect)
	pk.Register(SYSTEMMESSG, "SystemMessg", nil)
	pk.Register(SERVERSTATE, "ServerState", nil)
	pk.Register(CHECKVERSION, "CheckVersion", CheckVersion)
	pk.Register(URLTOCLIENT, "URLToClient", nil)
	pk.Register(PUBLIC_KEY, "PublicKey", PublicKey)
	pk.Register(PRE_SERVER_ENV_REQUEST, "PreServerEnvRequest", PreServerEnvRequest)
}

func RegisterFunc() {
	script.RegisterFunc("sendClientPacket", sessionPacketFunc{})
	script.RegisterFunc("sendClientMessage", clientMessageFunc{Fn: SystemMessgEx})
}
