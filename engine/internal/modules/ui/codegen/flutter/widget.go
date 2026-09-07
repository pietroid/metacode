// Package flutter implements the Flutter code-generation step for the UI module.
package flutter

import (
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/codegen"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
)

//go:embed templates/*.tmpl
var templates embed.FS

// Generate emits one StatelessWidget Dart file per top-level UI symbol.
func Generate(app *ir.IR, c *catalog.Catalog, outDir string) error {
	pagesDir := filepath.Join(outDir, "lib", "pages")
	widgetsDir := filepath.Join(outDir, "lib", "widgets")
	if err := os.MkdirAll(pagesDir, 0755); err != nil {
		return fmt.Errorf("create pages dir: %w", err)
	}
	if err := os.MkdirAll(widgetsDir, 0755); err != nil {
		return fmt.Errorf("create widgets dir: %w", err)
	}

	tmpl, err := template.ParseFS(templates, "templates/*.tmpl")
	if err != nil {
		return fmt.Errorf("parse templates: %w", err)
	}

	for _, comp := range app.UI {
		if err := writeWidget(comp, app.Symbols, c, pagesDir, widgetsDir, tmpl); err != nil {
			return fmt.Errorf("widget %s: %w", comp.Name, err)
		}
	}
	return nil
}

type widgetData struct {
	Name      string
	ClassName string
	Params    string
	Fields    string
	Imports   string
	Root      string
}

func writeWidget(comp ir.UIComponent, symbols ir.SymbolTable, c *catalog.Catalog, pagesDir, widgetsDir string, tmpl *template.Template) error {
	className := shared.PascalCase(comp.Name)
	fileName := shared.SnakeCase(comp.Name) + ".dart"
	dir := widgetsDir
	if isPage(comp.Name) {
		dir = pagesDir
	}

	vars := shared.UniqueStrings(comp.Variables)
	imports := collectImports(comp, comp.Name, symbols, dir)

	var params strings.Builder
	var fields strings.Builder
	for _, v := range vars {
		params.WriteString(fmt.Sprintf(", required this.%s", v))
		fields.WriteString(fmt.Sprintf("\n  final String %s;", v))
	}

	root := renderTopLevel(comp, symbols, c)

	data := widgetData{
		Name:      comp.Name,
		ClassName: className,
		Params:    params.String(),
		Fields:    fields.String(),
		Imports:   imports,
		Root:      root,
	}

	path := filepath.Join(dir, fileName)
	return codegen.ExecuteTemplate(tmpl, "widget.dart.tmpl", path, data)
}

func isPage(name string) bool {
	if strings.EqualFold(name, "homePage") {
		return true
	}
	return strings.HasSuffix(name, "Page")
}

func collectImports(comp ir.UIComponent, self string, symbols ir.SymbolTable, currentDir string) string {
	refs := make(map[string]bool)
	collectWidgetRefs(comp, self, symbols, refs)
	collectRawWidgetRefs(comp.Props, self, symbols, refs)
	if len(refs) == 0 {
		return ""
	}

	var b strings.Builder
	for name := range refs {
		rel := relativeImportPath(currentDir, name)
		b.WriteString(fmt.Sprintf("\nimport '%s/%s.dart';", rel, shared.SnakeCase(name)))
	}
	return b.String()
}

func collectRawWidgetRefs(raw any, self string, symbols ir.SymbolTable, refs map[string]bool) {
	switch v := raw.(type) {
	case string:
		if v != self {
			if sym, ok := symbols.Lookup(v); ok && sym.Kind == "widget" {
				refs[v] = true
			}
		}
	case map[string]any:
		for key, val := range v {
			if key != self {
				if sym, ok := symbols.Lookup(key); ok && sym.Kind == "widget" {
					refs[key] = true
				}
			}
			collectRawWidgetRefs(val, self, symbols, refs)
		}
	case []any:
		for _, item := range v {
			collectRawWidgetRefs(item, self, symbols, refs)
		}
	}
}

func relativeImportPath(currentDir, targetName string) string {
	currentBase := filepath.Base(currentDir)
	targetBase := "widgets"
	if isPage(targetName) {
		targetBase = "pages"
	}
	if currentBase == targetBase {
		return "."
	}
	if currentBase == "pages" && targetBase == "widgets" {
		return "../widgets"
	}
	if currentBase == "widgets" && targetBase == "pages" {
		return "../pages"
	}
	return targetBase
}

func collectWidgetRefs(comp ir.UIComponent, self string, symbols ir.SymbolTable, refs map[string]bool) {
	if comp.Name != self {
		if sym, ok := symbols.Lookup(comp.Name); ok && sym.Kind == "widget" {
			refs[comp.Name] = true
		}
	}
	for _, child := range comp.Children {
		collectWidgetRefs(child, self, symbols, refs)
	}
}

func renderTopLevel(comp ir.UIComponent, symbols ir.SymbolTable, c *catalog.Catalog) string {
	return renderComponent(comp, symbols, c, true)
}

func renderComponent(comp ir.UIComponent, symbols ir.SymbolTable, c *catalog.Catalog, topLevel bool) string {
	if sym, ok := c.Find(comp.Kind); ok {
		return renderCatalogWidget(comp, sym, symbols, c, topLevel)
	}
	// Custom widget reference.
	return fmt.Sprintf("const %s()", shared.PascalCase(comp.Name))
}

func renderCatalogWidget(comp ir.UIComponent, sym catalog.Symbol, symbols ir.SymbolTable, c *catalog.Catalog, topLevel bool) string {
	var args []string

	if topLevel {
		args = append(args, fmt.Sprintf("key: const Key(%s)", shared.DartStringLiteral(comp.Name)))
	}

	if sym.DefaultProp != "" {
		if childArg := renderDefaultProp(comp, sym, symbols, c); childArg != "" {
			args = append(args, childArg)
		}
	}

	for prop, val := range comp.Props {
		if prop == sym.DefaultProp {
			continue
		}
		expectsWidget := c.WidgetProp(comp.Kind, prop)
		args = append(args, fmt.Sprintf("%s: %s", prop, renderNamedProp(prop, val, expectsWidget, symbols, c)))
	}

	for _, cb := range requiredCallbacks(comp.Kind) {
		if _, ok := comp.Props[cb]; !ok {
			if cb == catalog.PropIcon {
				args = append(args, "icon: const Icon(Icons.add)")
			} else {
				args = append(args, fmt.Sprintf("%s: null", cb))
			}
		}
	}

	if len(args) == 1 {
		return fmt.Sprintf("%s(%s)", sym.FlutterWidget, args[0])
	}
	return fmt.Sprintf("%s(\n%s\n)", sym.FlutterWidget, shared.Indent(strings.Join(args, ",\n")))
}

func requiredCallbacks(kind string) []string {
	switch kind {
	case "elevatedButton", "textButton", "floatingActionButton":
		return []string{"onPressed"}
	case "iconButton":
		return []string{catalog.PropIcon, "onPressed"}
	default:
		return nil
	}
}

func renderDefaultProp(comp ir.UIComponent, sym catalog.Symbol, symbols ir.SymbolTable, c *catalog.Catalog) string {
	prop := sym.DefaultProp
	if prop == catalog.PropChild && len(comp.Children) > 0 {
		return fmt.Sprintf("%s: %s", prop, renderComponent(comp.Children[0], symbols, c, false))
	}
	if prop == catalog.PropChildren && len(comp.Children) > 0 {
		return fmt.Sprintf("%s: %s", prop, renderChildrenList(comp.Children, symbols, c))
	}
	if val, ok := comp.Props[prop]; ok {
		expectsWidget := c.WidgetProp(comp.Kind, prop)
		if prop == catalog.PropData {
			return renderPropValue(val, expectsWidget, symbols, c)
		}
		return fmt.Sprintf("%s: %s", prop, renderPropValue(val, expectsWidget, symbols, c))
	}
	return ""
}

var impliedWidgetKind = map[string]string{
	catalog.PropAppBar:    "appBar",
	catalog.PropFAB:       "floatingActionButton",
	catalog.PropBottomNav: "bottomNavigationBar",
	catalog.PropDrawer:    "drawer",
}

func renderNamedProp(prop string, val any, expectsWidget bool, symbols ir.SymbolTable, c *catalog.Catalog) string {
	if kind, ok := impliedWidgetKind[prop]; ok {
		if props, ok := val.(map[string]any); ok {
			comp := ir.UIComponent{
				Name:  kind,
				Kind:  kind,
				Props: props,
			}
			return renderComponent(comp, symbols, c, false)
		}
	}
	return renderPropValue(val, expectsWidget, symbols, c)
}

func renderChildrenList(children []ir.UIComponent, symbols ir.SymbolTable, c *catalog.Catalog) string {
	var parts []string
	for _, child := range children {
		parts = append(parts, renderComponent(child, symbols, c, false))
	}
	return fmt.Sprintf("[\n%s\n]", shared.Indent(strings.Join(parts, ",\n")))
}

func renderPropValue(val any, expectsWidget bool, symbols ir.SymbolTable, c *catalog.Catalog) string {
	switch v := val.(type) {
	case string:
		if expectsWidget {
			if sym, ok := symbols.Lookup(v); ok && sym.Kind == "widget" {
				return fmt.Sprintf("const %s()", shared.PascalCase(v))
			}
			if shared.IsVariableIdentifier(v) && !c.IsKnown(v) {
				return fmt.Sprintf("Text(%s)", v)
			}
			return fmt.Sprintf("const Text(%s)", shared.DartStringLiteral(v))
		}
		if shared.IsVariableIdentifier(v) && !c.IsKnown(v) {
			return v
		}
		return shared.DartStringLiteral(v)
	case map[string]any:
		return renderRawWidget(v, symbols, c)
	case []any:
		return renderRawList(v, expectsWidget, symbols, c)
	default:
		return fmt.Sprintf("%v", v)
	}
}

func renderRawWidget(raw map[string]any, symbols ir.SymbolTable, c *catalog.Catalog) string {
	if len(raw) != 1 {
		return "Container()"
	}
	for name, value := range raw {
		if sym, ok := c.Find(name); ok {
			comp := ir.UIComponent{
				Name:  name,
				Kind:  name,
				Props: map[string]any{sym.DefaultProp: value},
			}
			return renderComponent(comp, symbols, c, false)
		}
		if sym, ok := symbols.Lookup(name); ok && sym.Kind == "widget" {
			return fmt.Sprintf("const %s()", shared.PascalCase(name))
		}
		return "Container()"
	}
	return "Container()"
}

func renderRawList(raw []any, expectsWidget bool, symbols ir.SymbolTable, c *catalog.Catalog) string {
	var parts []string
	for _, item := range raw {
		parts = append(parts, renderPropValue(item, expectsWidget, symbols, c))
	}
	return fmt.Sprintf("[\n%s\n]", shared.Indent(strings.Join(parts, ",\n")))
}
