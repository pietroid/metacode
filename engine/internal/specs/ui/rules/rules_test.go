package uirules

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

func TestValidateUnknownProp(t *testing.T) {
	comp := model.UIComponent{
		Name: "homePage",
		Kind: "text",
		Props: map[string]any{
			"unknownProp": "value",
		},
	}
	errs := Validate([]model.UIComponent{comp}, catalog.Default())
	if len(errs) != 1 {
		t.Fatalf("expected 1 error, got %d: %v", len(errs), errs)
	}
}

func TestValidateCustomWidgetIgnored(t *testing.T) {
	comp := model.UIComponent{
		Name: "incrementButton",
		Kind: "custom",
	}
	errs := Validate([]model.UIComponent{comp}, catalog.Default())
	if len(errs) != 0 {
		t.Fatalf("expected no errors for custom widget, got %v", errs)
	}
}
