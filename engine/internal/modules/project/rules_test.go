package project

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/ir"
)

func TestValidateMissingName(t *testing.T) {
	errs := Validate(ir.Project{})
	if len(errs) != 1 {
		t.Fatalf("expected 1 error, got %d: %v", len(errs), errs)
	}
}

func TestPackageName(t *testing.T) {
	cases := []struct {
		in, want string
	}{
		{"counter_app", "counter_app"},
		{"Counter App", "counter_app"},
		{"my-app", "my_app"},
		{"123app", "app_123app"},
		{"", "unnamed_app"},
	}
	for _, tc := range cases {
		got := PackageName(tc.in)
		if got != tc.want {
			t.Errorf("PackageName(%q) = %q, want %q", tc.in, got, tc.want)
		}
	}
}
