package datarules

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
)

func TestValidateMissingValueType(t *testing.T) {
	errs := Validate([]model.Store{{Name: "counterStore"}})
	if len(errs) != 1 {
		t.Fatalf("expected 1 error, got %d: %v", len(errs), errs)
	}
}
