// Package navigationflutter writes the Flutter route table: one GoRouter built
// from navigation.yaml.
//
// It is deterministic and complete. Where the app can go, what each
// destination shows and how it appears are all in the spec, so no model is
// asked for any of it; what a model writes is the push, in the wrapper of the
// widget whose event runs it.
package navigationflutter

import (
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"text/template"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/ui/rules"
)

//go:embed templates/*.tmpl
var templates embed.FS

// pageClasses maps a route's presentation to the Page class that builds it.
// The two custom ones are declared in the same file, and only when a route
// uses them.
var pageClasses = map[model.RouteType]string{
	model.RoutePage:        "MaterialPage",
	model.RouteBottomSheet: "ModalBottomSheetPage",
	model.RouteDialog:      "DialogPage",
}

type routerData struct {
	InitialLocation string
	Routes          []routeData
	Imports         []string
	UsesBottomSheet bool
	UsesDialog      bool
}

type routeData struct {
	Name      string
	Path      string
	PageClass string
	Child     string
}

// Generate writes lib/navigation/router.dart. A project with no routes has no
// router: its single page is reached the way it always was.
func Generate(app *model.App, outDir string) error {
	if !app.Navigation.Declared() {
		return nil
	}

	data, err := buildRouterData(app)
	if err != nil {
		return err
	}

	tmpl, err := template.ParseFS(templates, "templates/*.tmpl")
	if err != nil {
		return fmt.Errorf("parse templates: %w", err)
	}

	path := filepath.Join(outDir, filepath.FromSlash(dart.RouterFile()))
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return fmt.Errorf("create navigation dir: %w", err)
	}
	return dart.ExecuteTemplate(tmpl, "router.dart.tmpl", path, data)
}

func buildRouterData(app *model.App) (routerData, error) {
	initial, ok := app.Navigation.Initial()
	if !ok {
		return routerData{}, fmt.Errorf("initialRoute %q is not a declared route", app.Navigation.InitialRoute)
	}

	wrapped := uirules.WrapperWidgets(app)
	data := routerData{
		InitialLocation: dart.RoutePath(initial.Name),
		UsesBottomSheet: app.Navigation.Uses(model.RouteBottomSheet),
		UsesDialog:      app.Navigation.Uses(model.RouteDialog),
	}

	var imports []string
	for _, route := range app.Navigation.Routes {
		child, file := childOf(route.Child, wrapped)
		imports = append(imports, "../"+dart.LibImport(file))
		data.Routes = append(data.Routes, routeData{
			Name:      route.Name,
			Path:      dart.RoutePath(route.Name),
			PageClass: pageClasses[route.Type],
			Child:     child,
		})
	}

	imports = dart.UniqueStrings(imports)
	sort.Strings(imports)
	data.Imports = imports
	return data, nil
}

// childOf is the expression a route builds, and the file it comes from: the
// widget's wrapper when it has one, and the widget itself when there is
// nothing in it to wire. It is the same rule a wrapper follows for its own
// children, because a route is one more place a widget is reached from.
func childOf(widget string, wrapped map[string]bool) (string, string) {
	if wrapped[widget] {
		return fmt.Sprintf("const %s()", dart.WrapperClass(widget)), dart.WrapperFile(widget)
	}
	return fmt.Sprintf("const %s()", dart.WidgetClass(widget)), dart.WidgetFile(widget)
}
