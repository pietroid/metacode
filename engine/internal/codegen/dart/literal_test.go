package dart

import "testing"

func TestDartTypeFor(t *testing.T) {
	cases := []struct {
		in, want string
	}{
		{"int", "int"},
		{"string", "String"},
		{"bool", "bool"},
		{"number", "num"},
	}
	for _, tc := range cases {
		got := DartTypeFor(tc.in)
		if got != tc.want {
			t.Errorf("DartTypeFor(%q) = %q, want %q", tc.in, got, tc.want)
		}
	}
}

func TestDartLiteral(t *testing.T) {
	if got := DartLiteral(0, "int"); got != "0" {
		t.Errorf("DartLiteral(0) = %q, want 0", got)
	}
	if got := DartLiteral("hello", "String"); got != "'hello'" {
		t.Errorf("DartLiteral(hello) = %q, want 'hello'", got)
	}
}
