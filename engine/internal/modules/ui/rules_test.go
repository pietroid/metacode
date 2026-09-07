package ui

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
)

func TestValidateUnknownProp(t *testing.T) {
	comp := ir.UIComponent{
		Name: "homePage",
		Kind: "text",
		Props: map[string]any{
			"unknownProp": "value",
		},
	}
	errs := Validate([]ir.UIComponent{comp}, catalog.New())
	if len(errs) != 1 {
		t.Fatalf("expected 1 error, got %d: %v", len(errs), errs)
	}
}

func TestValidateCustomWidgetIgnored(t *testing.T) {
	comp := ir.UIComponent{
		Name: "counterButton",
		Kind: "custom",
	}
	errs := Validate([]ir.UIComponent{comp}, catalog.New())
	if len(errs) != 0 {
		t.Fatalf("expected no errors for custom widget, got %v", errs)
	}
}
