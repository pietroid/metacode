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
		{"list(string)", "List<String>"},
		{"list(task)", "List<Task>"},
		{"datetime", "DateTime"},
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

func TestDartLiteralListOfMaps(t *testing.T) {
	v := []any{map[string]any{"done": false, "description": "Buy milk"}}
	want := "[{'description': 'Buy milk', 'done': false}]"
	if got := DartLiteral(v, "List<dynamic>"); got != want {
		t.Errorf("DartLiteral(list) = %q, want %q", got, want)
	}
}

func TestDartLiteralBuildsADeclaredModel(t *testing.T) {
	v := []any{map[string]any{"done": false, "description": "Buy milk"}}
	want := "[Task(description: 'Buy milk', done: false)]"
	if got := DartLiteral(v, "List<Task>"); got != want {
		t.Errorf("DartLiteral(list of task) = %q, want %q", got, want)
	}
}
