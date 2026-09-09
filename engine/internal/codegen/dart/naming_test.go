package dart

import "testing"

func TestIsPageName(t *testing.T) {
	cases := []struct {
		name string
		want bool
	}{
		{"homePage", true},
		{"settingsPage", true},
		{"incrementButton", false},
	}
	for _, tc := range cases {
		if got := IsPageName(tc.name); got != tc.want {
			t.Errorf("IsPageName(%q) = %v, want %v", tc.name, got, tc.want)
		}
	}
}

func TestStoreBaseName(t *testing.T) {
	if got := StoreBaseName("counterStore"); got != "counter" {
		t.Errorf("StoreBaseName(counterStore) = %q, want counter", got)
	}
	if got := StoreBaseName("counter"); got != "counter" {
		t.Errorf("StoreBaseName(counter) = %q, want counter", got)
	}
}
