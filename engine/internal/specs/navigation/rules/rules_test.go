package navigationrules

import (
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
)

func TestBuildReadsTheRouteTable(t *testing.T) {
	nav, err := Build(map[string]any{
		"initialRoute": "home",
		"routes": map[string]any{
			"home":    map[string]any{"child": "homePage", "type": "page"},
			"addTask": map[string]any{"child": "addTaskSheet", "type": "bottomSheet"},
		},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if nav.InitialRoute != "home" {
		t.Errorf("expected the app to open on home, got %q", nav.InitialRoute)
	}
	route, ok := nav.Route("addTask")
	if !ok {
		t.Fatalf("expected an addTask route, got %v", nav.Routes)
	}
	if route.Child != "addTaskSheet" || route.Type != model.RouteBottomSheet {
		t.Errorf("unexpected route: %+v", route)
	}
	if !nav.Uses(model.RouteBottomSheet) || nav.Uses(model.RouteDialog) {
		t.Errorf("expected a sheet and no dialog, got %v", nav.Routes)
	}
}

func TestNoFileNoRoutes(t *testing.T) {
	nav, err := Build(nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if nav.Declared() {
		t.Errorf("expected no routes, got %v", nav.Routes)
	}
}

// The presentation is the one thing the route table exists to say, so leaving
// it out is an error rather than a page.
func TestTypeIsRequired(t *testing.T) {
	for name, routes := range map[string]any{
		"no type":      map[string]any{"home": map[string]any{"child": "homePage"}},
		"unknown type": map[string]any{"home": map[string]any{"child": "homePage", "type": "drawer"}},
		"no child":     map[string]any{"home": map[string]any{"type": "page"}},
	} {
		if _, err := Build(map[string]any{"initialRoute": "home", "routes": routes}); err == nil {
			t.Errorf("%s: expected an error", name)
		}
	}
}

func TestValidateChecksTheTableAgainstTheWidgets(t *testing.T) {
	app := &model.App{
		Symbols: model.NewSymbolTable(),
		Navigation: model.Navigation{
			InitialRoute: "home",
			Routes: []model.Route{
				{Name: "home", Child: "homePage", Type: model.RoutePage},
				{Name: "addTask", Child: "missingWidget", Type: model.RouteBottomSheet},
			},
		},
	}
	app.Symbols.Widgets["homePage"] = model.UIComponent{Name: "homePage"}

	errs := Validate(app)
	if len(errs) != 1 || !strings.Contains(errs[0].Error(), "missingWidget") {
		t.Fatalf("expected one error about the missing widget, got %v", errs)
	}
}

// A modal opens over something. Starting on one would leave the barrier with
// nothing behind it.
func TestValidateRejectsAModalAsTheInitialRoute(t *testing.T) {
	app := &model.App{
		Symbols: model.NewSymbolTable(),
		Navigation: model.Navigation{
			InitialRoute: "addTask",
			Routes:       []model.Route{{Name: "addTask", Child: "sheet", Type: model.RouteBottomSheet}},
		},
	}
	app.Symbols.Widgets["sheet"] = model.UIComponent{Name: "sheet"}

	errs := Validate(app)
	if len(errs) != 1 || !strings.Contains(errs[0].Error(), "shown over a page") {
		t.Fatalf("expected the initial route to be rejected, got %v", errs)
	}
}

func TestValidateNeedsAnInitialRoute(t *testing.T) {
	app := &model.App{
		Symbols:    model.NewSymbolTable(),
		Navigation: model.Navigation{Routes: []model.Route{{Name: "home", Child: "homePage", Type: model.RoutePage}}},
	}
	app.Symbols.Widgets["homePage"] = model.UIComponent{Name: "homePage"}

	if errs := Validate(app); len(errs) != 1 {
		t.Fatalf("expected one error, got %v", errs)
	}
}
