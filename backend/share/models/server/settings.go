package server

import "cabal-online-community-server/share/encryption"

type Settings struct {
	XorKeyTable encryption.XorKeyTable
}
