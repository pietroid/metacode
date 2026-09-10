// Package navigationrules interprets navigation.yaml: the route table, and the
// route the app opens on.
//
// A route is structure, not logic. It says a destination exists, which widget
// it shows, and how it appears. Which event moves the app there is a behavior,
// resolved in specs/actions/rules, so nothing in this package reads a
// scenario.
package navigationrules

import (
	"fmt"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/order"
)

// routeTypes is every presentation a route may declare.
var routeTypes = []model.RouteType{model.RoutePage, model.RouteBottomSheet, model.RouteDialog}

// Build reads navigation.yaml. A project without one has no routes, which is
// not an error: the app is one page and the UI spec already says which.
func Build(raw map[string]any) (model.Navigation, error) {
	if len(raw) == 0 {
		return model.Navigation{}, nil
	}

	nav := model.Navigation{}
	if v, ok := raw["initialRoute"]; ok {
		s, ok := v.(string)
		if !ok {
			return nav, fmt.Errorf("initialRoute must name a route, got %T", v)
		}
		nav.InitialRoute = s
	}

	rawRoutes, ok := raw["routes"]
	if !ok {
		return nav, fmt.Errorf("navigation.yaml has no `routes:` key")
	}
	routes, ok := rawRoutes.(map[string]any)
	if !ok {
		return nav, fmt.Errorf("routes must be a mapping of a route name to its declaration, got %T", rawRoutes)
	}

	for _, name := range order.Keys(routes) {
		route, err := buildRoute(name, routes[name])
		if err != nil {
			return model.Navigation{}, err
		}
		nav.Routes = append(nav.Routes, route)
	}
	return nav, nil
}

func buildRoute(name string, raw any) (model.Route, error) {
	fields, ok := raw.(map[string]any)
	if !ok {
		return model.Route{}, fmt.Errorf("route %q must be a mapping with `child:` and `type:`, got %T", name, raw)
	}

	child, ok := fields["child"].(string)
	if !ok || child == "" {
		return model.Route{}, fmt.Errorf("route %q has no `child:` naming the widget it shows", name)
	}

	// The type is required rather than defaulted to a page. A route's
	// presentation is the one thing the route table exists to say, and a
	// silent default is how a sheet ships as a full-screen page.
	kind, ok := fields["type"].(string)
	if !ok || kind == "" {
		return model.Route{}, fmt.Errorf("route %q has no `type:`. It is one of %s", name, typeList())
	}
	for _, t := range routeTypes {
		if model.RouteType(kind) == t {
			return model.Route{Name: name, Child: child, Type: t}, nil
		}
	}
	return model.Route{}, fmt.Errorf("route %q has type %q, which is not one of %s", name, kind, typeList())
}

// Validate checks the route table against the widgets the UI spec declares. It
// returns errors rather than warnings because every one of them produces a
// router that does not compile.
func Validate(app *model.App) []error {
	nav := app.Navigation
	if !nav.Declared() {
		return nil
	}

	var errs []error
	seenChild := make(map[string]string, len(nav.Routes))
	for _, route := range nav.Routes {
		if _, ok := app.Symbols.Widgets[route.Child]; !ok {
			errs = append(errs, fmt.Errorf("navigation.yaml > %s: no widget named %q is declared in ui.yaml", route.Name, route.Child))
		}
		if other, clash := seenChild[route.Child]; clash {
			errs = append(errs, fmt.Errorf("navigation.yaml > %s: %q is already shown by route %q, so a push cannot say which one is meant", route.Name, route.Child, other))
		}
		seenChild[route.Child] = route.Name
	}

	if nav.InitialRoute == "" {
		errs = append(errs, fmt.Errorf("navigation.yaml declares routes but no `initialRoute:`"))
		return errs
	}
	initial, ok := nav.Initial()
	if !ok {
		errs = append(errs, fmt.Errorf("navigation.yaml: initialRoute %q is not a declared route", nav.InitialRoute))
		return errs
	}
	// A modal opens over something. Starting the app on one would leave the
	// barrier with nothing behind it, and popping it would leave nothing at
	// all.
	if initial.Type.IsModal() {
		errs = append(errs, fmt.Errorf("navigation.yaml: initialRoute %q is a %s, which is shown over a page rather than as one", initial.Name, initial.Type))
	}
	return errs
}

func typeList() string {
	out := ""
	for i, t := range routeTypes {
		if i > 0 {
			out += ", "
		}
		out += string(t)
	}
	return out
}
