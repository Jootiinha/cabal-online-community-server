package policy

import (
	"fmt"
	"os"
	"strconv"
)

// InitialHP changes only new characters; 100 preserves upstream values.
func InitialHP(base int) (uint16, error) {
	percent := 100
	if raw := os.Getenv("CABAL_INITIAL_HP_PERCENT"); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil {
			return 0, fmt.Errorf("invalid initial HP percentage")
		}
		percent = n
	}
	return ScaleHP(base, percent)
}

func ScaleHP(base, percent int) (uint16, error) {
	if base < 1 || base > 65535 || percent < 1 || percent > 1000 {
		return 0, fmt.Errorf("initial HP or percentage out of range")
	}
	hp := int64(base) * int64(percent) / 100
	if hp < 1 || hp > 65535 {
		return 0, fmt.Errorf("scaled HP exceeds uint16 bounds")
	}
	return uint16(hp), nil
}
