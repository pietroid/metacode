// Package flutter implements the Flutter code-generation step for the UI module.
package flutter

import (
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"text/template"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/core/order"
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

	refs := referencedWidgets(comp, symbols)
	r := &renderer{
		symbols:     symbols,
		catalog:     c,
		ownEvents:   eventsOf(comp.Name, symbols),
		childEvents: childEventParams(refs, symbols),
	}

	vars := shared.UniqueStrings(comp.Variables)

	var params strings.Builder
	var fields strings.Builder
	for _, v := range vars {
		params.WriteString(fmt.Sprintf(", required this.%s", v))
		fields.WriteString(fmt.Sprintf("\n  final String %s;", v))
	}
	// Events are optional: a dumb widget must still render on its own, and a
	// wrapper supplies the callback when there is something to wire.
	for _, name := range r.callbackParams() {
		params.WriteString(fmt.Sprintf(", this.%s", name))
		fields.WriteString(fmt.Sprintf("\n  final VoidCallback? %s;", name))
	}

	data := widgetData{
		Name:      comp.Name,
		ClassName: className,
		Params:    params.String(),
		Fields:    fields.String(),
		Imports:   collectImports(refs, dir),
		Root:      r.renderTopLevel(comp),
	}

	path := filepath.Join(dir, fileName)
	return codegen.ExecuteTemplate(tmpl, "widget.dart.tmpl", path, data)
}

// renderer carries everything the render pass needs: the symbol table, the
// catalog, and the callback parameters this widget exposes.
type renderer struct {
	symbols ir.SymbolTable
	catalog *catalog.Catalog

	// ownEvents are events declared on this widget, e.g. "onPressed". They are
	// exposed under their own name and bound to this widget's root.
	ownEvents []string

	// childEvents maps a referenced widget name to its event -> parameter name,
	// e.g. incrementButton -> {onPressed: incrementButtonOnPressed}. A widget that
	// embeds another widget forwards that widget's callbacks, so a single
	// wrapper at the top can wire a whole page.
	childEvents map[string]map[string]string
}

// callbackParams lists every callback parameter this widget exposes, in a
// stable order: its own events first, then forwarded child events.
func (r *renderer) callbackParams() []string {
	out := append([]string(nil), r.ownEvents...)
	for _, child := range order.Keys(r.childEvents) {
		events := r.childEvents[child]
		for _, event := range order.Keys(events) {
			out = append(out, events[event])
		}
	}
	return out
}

// eventsOf returns the events declared on widget, in a stable order.
func eventsOf(widget string, symbols ir.SymbolTable) []string {
	var out []string
	for _, path := range order.Keys(symbols.Events) {
		if ref := symbols.Events[path]; ref.Widget == widget {
			out = append(out, ref.Event)
		}
	}
	return shared.UniqueStrings(out)
}

// childEventParams names the forwarded parameter for every event of every
// referenced widget: incrementButton.onPressed becomes incrementButtonOnPressed.
func childEventParams(refs []string, symbols ir.SymbolTable) map[string]map[string]string {
	out := make(map[string]map[string]string)
	for _, name := range refs {
		events := eventsOf(name, symbols)
		if len(events) == 0 {
			continue
		}
		params := make(map[string]string, len(events))
		for _, event := range events {
			params[event] = name + shared.PascalCase(event)
		}
		out[name] = params
	}
	return out
}

func isPage(name string) bool {
	if strings.EqualFold(name, "homePage") {
		return true
	}
	return strings.HasSuffix(name, "Page")
}

// referencedWidgets lists the declared widgets that comp embeds, sorted.
func referencedWidgets(comp ir.UIComponent, symbols ir.SymbolTable) []string {
	refs := make(map[string]bool)
	collectWidgetRefs(comp, comp.Name, symbols, refs)
	collectRawWidgetRefs(comp.Props, comp.Name, symbols, refs)

	out := make([]string, 0, len(refs))
	for name := range refs {
		out = append(out, name)
	}
	sort.Strings(out)
	return out
}

func collectImports(refs []string, currentDir string) string {
	if len(refs) == 0 {
		return ""
	}
	var b strings.Builder
	for _, name := range refs {
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
		for _, key := range order.Keys(v) {
			if key != self {
				if sym, ok := symbols.Lookup(key); ok && sym.Kind == "widget" {
					refs[key] = true
				}
			}
			collectRawWidgetRefs(v[key], self, symbols, refs)
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

func (r *renderer) renderTopLevel(comp ir.UIComponent) string {
	return r.renderComponent(comp, true)
}

func (r *renderer) renderComponent(comp ir.UIComponent, topLevel bool) string {
	if sym, ok := r.catalog.Find(comp.Kind); ok {
		return r.renderCatalogWidget(comp, sym, topLevel)
	}
	// Custom widget reference.
	return r.renderWidgetRef(comp.Name)
}

// renderWidgetRef instantiates another declared widget, forwarding the
// callbacks this widget exposes on its behalf.
func (r *renderer) renderWidgetRef(name string) string {
	params := r.childEvents[name]
	if len(params) == 0 {
		return fmt.Sprintf("const %s()", shared.PascalCase(name))
	}
	var args []string
	for _, event := range order.Keys(params) {
		args = append(args, fmt.Sprintf("%s: %s", event, params[event]))
	}
	return fmt.Sprintf("%s(%s)", shared.PascalCase(name), strings.Join(args, ", "))
}

func (r *renderer) renderCatalogWidget(comp ir.UIComponent, sym catalog.Symbol, topLevel bool) string {
	var args []string

	if topLevel {
		args = append(args, fmt.Sprintf("key: const Key(%s)", shared.DartStringLiteral(comp.Name)))
	}

	if sym.DefaultProp != "" {
		if childArg := r.renderDefaultProp(comp, sym); childArg != "" {
			args = append(args, childArg)
		}
	}

	for _, prop := range catalogPropOrder(sym, comp.Props) {
		if prop == sym.DefaultProp {
			continue
		}
		expectsWidget := r.catalog.WidgetProp(comp.Kind, prop)
		args = append(args, fmt.Sprintf("%s: %s", prop, r.renderNamedProp(prop, comp.Props[prop], expectsWidget)))
	}

	for _, cb := range requiredCallbacks(comp.Kind) {
		if _, ok := comp.Props[cb]; ok {
			continue
		}
		switch {
		case cb == catalog.PropIcon:
			args = append(args, "icon: const Icon(Icons.add)")
		case topLevel && r.exposesEvent(cb):
			// The behavior specs declare this event, so the widget takes it as
			// a parameter instead of being permanently disabled.
			args = append(args, fmt.Sprintf("%s: %s", cb, cb))
		default:
			args = append(args, fmt.Sprintf("%s: null", cb))
		}
	}

	if len(args) == 1 {
		return fmt.Sprintf("%s(%s)", sym.FlutterWidget, args[0])
	}
	return fmt.Sprintf("%s(\n%s\n)", sym.FlutterWidget, shared.Indent(strings.Join(args, ",\n")))
}

func (r *renderer) exposesEvent(event string) bool {
	for _, e := range r.ownEvents {
		if e == event {
			return true
		}
	}
	return false
}

// catalogPropOrder returns the props present on a component in a stable order:
// catalog order first, so generated Dart reads the way the catalog documents the
// widget, then any remaining props sorted by name.
func catalogPropOrder(sym catalog.Symbol, props map[string]any) []string {
	var ordered []string
	seen := make(map[string]bool, len(props))

	for _, p := range sym.AllowedProps {
		if _, ok := props[p]; ok && !seen[p] {
			ordered = append(ordered, p)
			seen[p] = true
		}
	}
	for _, p := range order.Keys(props) {
		if !seen[p] {
			ordered = append(ordered, p)
		}
	}
	return ordered
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

func (r *renderer) renderDefaultProp(comp ir.UIComponent, sym catalog.Symbol) string {
	prop := sym.DefaultProp
	if prop == catalog.PropChild && len(comp.Children) > 0 {
		return fmt.Sprintf("%s: %s", prop, r.renderComponent(comp.Children[0], false))
	}
	if prop == catalog.PropChildren && len(comp.Children) > 0 {
		return fmt.Sprintf("%s: %s", prop, r.renderChildrenList(comp.Children))
	}
	if val, ok := comp.Props[prop]; ok {
		expectsWidget := r.catalog.WidgetProp(comp.Kind, prop)
		if prop == catalog.PropData {
			return r.renderPropValue(val, expectsWidget)
		}
		return fmt.Sprintf("%s: %s", prop, r.renderPropValue(val, expectsWidget))
	}
	return ""
}

var impliedWidgetKind = map[string]string{
	catalog.PropAppBar:    "appBar",
	catalog.PropFAB:       "floatingActionButton",
	catalog.PropBottomNav: "bottomNavigationBar",
	catalog.PropDrawer:    "drawer",
}

func (r *renderer) renderNamedProp(prop string, val any, expectsWidget bool) string {
	if kind, ok := impliedWidgetKind[prop]; ok {
		if props, ok := val.(map[string]any); ok {
			comp := ir.UIComponent{
				Name:  kind,
				Kind:  kind,
				Props: props,
			}
			return r.renderComponent(comp, false)
		}
	}
	return r.renderPropValue(val, expectsWidget)
}

func (r *renderer) renderChildrenList(children []ir.UIComponent) string {
	var parts []string
	for _, child := range children {
		parts = append(parts, r.renderComponent(child, false))
	}
	return fmt.Sprintf("[\n%s\n]", shared.Indent(strings.Join(parts, ",\n")))
}

func (r *renderer) renderPropValue(val any, expectsWidget bool) string {
	switch v := val.(type) {
	case string:
		if expectsWidget {
			if sym, ok := r.symbols.Lookup(v); ok && sym.Kind == "widget" {
				return r.renderWidgetRef(v)
			}
			if shared.IsVariableIdentifier(v) && !r.catalog.IsKnown(v) {
				return fmt.Sprintf("Text(%s)", v)
			}
			return fmt.Sprintf("const Text(%s)", shared.DartStringLiteral(v))
		}
		if shared.IsVariableIdentifier(v) && !r.catalog.IsKnown(v) {
			return v
		}
		return shared.DartStringLiteral(v)
	case map[string]any:
		return r.renderRawWidget(v)
	case []any:
		return r.renderRawList(v, expectsWidget)
	default:
		return fmt.Sprintf("%v", v)
	}
}

func (r *renderer) renderRawWidget(raw map[string]any) string {
	if len(raw) != 1 {
		return "Container()"
	}
	for _, name := range order.Keys(raw) {
		value := raw[name]
		if sym, ok := r.catalog.Find(name); ok {
			comp := ir.UIComponent{
				Name:  name,
				Kind:  name,
				Props: map[string]any{sym.DefaultProp: value},
			}
			return r.renderComponent(comp, false)
		}
		if sym, ok := r.symbols.Lookup(name); ok && sym.Kind == "widget" {
			return r.renderWidgetRef(name)
		}
		return "Container()"
	}
	return "Container()"
}

func (r *renderer) renderRawList(raw []any, expectsWidget bool) string {
	var parts []string
	for _, item := range raw {
		parts = append(parts, r.renderPropValue(item, expectsWidget))
	}
	return fmt.Sprintf("[\n%s\n]", shared.Indent(strings.Join(parts, ",\n")))
}
