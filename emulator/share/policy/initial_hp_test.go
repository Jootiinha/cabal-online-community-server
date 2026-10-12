package policy

import "testing"

func TestInitialHP(t *testing.T) {
	for _, tc := range []struct {
		base, percent int
		want          uint16
		invalid       bool
	}{
		{100, 100, 100, false}, {100, 200, 200, false}, {101, 150, 151, false},
		{65535, 1000, 0, true}, {0, 100, 0, true}, {100, 0, 0, true}, {1, 1, 0, true},
	} {
		got, err := ScaleHP(tc.base, tc.percent)
		if (err != nil) != tc.invalid || got != tc.want {
			t.Fatalf("%+v: got %d, %v", tc, got, err)
		}
	}
	t.Setenv("CABAL_INITIAL_HP_PERCENT", "")
	if hp, err := InitialHP(100); hp != 100 || err != nil {
		t.Fatal(hp, err)
	}
	t.Setenv("CABAL_INITIAL_HP_PERCENT", "200")
	if hp, err := InitialHP(100); hp != 200 || err != nil {
		t.Fatal(hp, err)
	}
	t.Setenv("CABAL_INITIAL_HP_PERCENT", "garbage")
	if _, err := InitialHP(100); err == nil {
		t.Fatal("invalid configuration accepted")
	}
}
