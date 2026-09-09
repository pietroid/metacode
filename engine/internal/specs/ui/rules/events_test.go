package uirules_test

import (
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
	"github.com/pietroid/metacode/engine/internal/specs/ui/rules"
)

// widgetsFrom builds the UI half of a spec, which is all event addressing
// needs: the addresses come from the widget, not from the behaviors.
func widgetsFrom(t *testing.T, raw map[string]any, name string) model.UIComponent {
	t.Helper()
	wrapped := map[string]any{"widgets": raw}
	symbols := model.NewSymbolTable()
	if err := uirules.RegisterWidgets(wrapped, &symbols); err != nil {
		t.Fatalf("register widgets: %v", err)
	}
	components, err := uirules.Build(wrapped, symbols)
	if err != nil {
		t.Fatalf("build widgets: %v", err)
	}
	for _, comp := range components {
		if comp.Name == name {
			return comp
		}
	}
	t.Fatalf("widget %q not built", name)
	return model.UIComponent{}
}

// resolve returns the prop an address stands for, which is what the callers of
// ResolveEvent that these tests are about care to check.
func resolve(t *testing.T, comp model.UIComponent, members ...string) (string, error) {
	t.Helper()
	addressed, err := uirules.ResolveEvent(comp, members, catalog.Default())
	return addressed.Prop, err
}

// TestRootPropIsAddressable keeps the common case working: a widget written as
// one catalog widget has one of each of its props, so nothing has to be named.
func TestRootPropIsAddressable(t *testing.T) {
	comp := widgetsFrom(t, map[string]any{
		"incrementButton": map[string]any{"elevatedButton": map[string]any{"child": "Increment"}},
	}, "incrementButton")

	got, err := resolve(t, comp, "onPressed")
	if err != nil {
		t.Fatalf("expected onPressed to resolve: %v", err)
	}
	if got != "onPressed" {
		t.Errorf("expected the prop onPressed, got %q", got)
	}
}

// TestAliasIsTheAddress is the point of an alias: the spec names the event once,
// where the prop is, and behaviors use that name.
func TestAliasIsTheAddress(t *testing.T) {
	comp := widgetsFrom(t, map[string]any{
		"addTaskButton": map[string]any{
			"floatingActionButton": map[string]any{"child": "Add", "onPressed": "onAddTask"},
		},
	}, "addTaskButton")

	got, err := resolve(t, comp, "onAddTask")
	if err != nil {
		t.Fatalf("expected the alias to resolve: %v", err)
	}
	if got != "onPressed" {
		t.Errorf("expected the alias to stand for onPressed, got %q", got)
	}
}

// TestAliasShadowsTheProp is the other half: once an event has a name, that is
// its name. Two ways to say one thing is how a spec starts disagreeing with
// itself, and the alias is the one that says which widget is meant.
func TestAliasShadowsTheProp(t *testing.T) {
	comp := widgetsFrom(t, map[string]any{
		"addTaskButton": map[string]any{
			"floatingActionButton": map[string]any{"child": "Add", "onPressed": "onAddTask"},
		},
	}, "addTaskButton")

	_, err := resolve(t, comp, "onPressed")
	if err == nil {
		t.Fatal("expected an aliased prop not to answer to its prop name")
	}
	if !strings.Contains(err.Error(), "onAddTask") {
		t.Errorf("expected the error to name the alias, got %v", err)
	}
}

// TestUnknownEventIsRejected is the failure this rule exists for: an invented
// name used to generate a parameter nothing rendered, a button wired to
// nothing, and a test that failed on a value instead of on the spec.
func TestUnknownEventIsRejected(t *testing.T) {
	comp := widgetsFrom(t, map[string]any{
		"addTaskButton": map[string]any{"floatingActionButton": map[string]any{"child": "Add"}},
	}, "addTaskButton")

	_, err := resolve(t, comp, "onWiggle")
	if err == nil {
		t.Fatal("expected an unknown event to be rejected")
	}
	if !strings.Contains(err.Error(), "onPressed") {
		t.Errorf("expected the error to list what is addressable, got %v", err)
	}
}

// TestAmbiguousInnerWidgetIsRejected is the question a path cannot answer: two
// buttons under one row, and nothing saying which one fires.
func TestAmbiguousInnerWidgetIsRejected(t *testing.T) {
	comp := widgetsFrom(t, map[string]any{
		"counterControls": map[string]any{
			"row": []any{
				map[string]any{"elevatedButton": "Increment"},
				map[string]any{"elevatedButton": "Decrement"},
			},
		},
	}, "counterControls")

	if _, err := resolve(t, comp, "onPressed"); err == nil {
		t.Error("expected a row with no onPressed of its own to be rejected")
	}

	_, err := resolve(t, comp, "elevatedButton", "onPressed")
	if err == nil {
		t.Fatal("expected two buttons of the same kind to be ambiguous")
	}
	if !strings.Contains(err.Error(), "2 elevatedButton") {
		t.Errorf("expected the error to count the candidates, got %v", err)
	}
}

// TestPathReachesAnUnnamedInnerWidget covers the way out when there is exactly
// one candidate: naming the catalog widget on the way is unambiguous, so it
// resolves without an alias.
func TestPathReachesAnUnnamedInnerWidget(t *testing.T) {
	comp := widgetsFrom(t, map[string]any{
		"controls": map[string]any{
			"row": []any{map[string]any{"elevatedButton": "Increment"}},
		},
	}, "controls")

	got, err := resolve(t, comp, "elevatedButton", "onPressed")
	if err != nil {
		t.Fatalf("expected one candidate to resolve: %v", err)
	}
	if got != "onPressed" {
		t.Errorf("expected the prop onPressed, got %q", got)
	}
}

// TestRowSelectorIsNotPartOfTheAddress: which row fired an event is not part of
// which event it is.
func TestRowSelectorIsNotPartOfTheAddress(t *testing.T) {
	comp := widgetsFrom(t, map[string]any{
		"taskCheckbox": map[string]any{
			"checkbox": map[string]any{"value": "taskDone", "onChanged": "taskToggled"},
		},
	}, "taskCheckbox")

	got, err := resolve(t, comp, model.RowFirst, "taskToggled")
	if err != nil {
		t.Fatalf("expected a row-selected alias to resolve: %v", err)
	}
	if got != "onChanged" {
		t.Errorf("expected the prop onChanged, got %q", got)
	}
}
