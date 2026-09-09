// Package flutter implements the Flutter code-generation step for the UI module.
package uiflutter

import (
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/order"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
	"github.com/pietroid/metacode/engine/internal/specs/ui/rules"
)

//go:embed templates/*.tmpl
var templates embed.FS

// Generate emits one StatelessWidget Dart file per top-level UI symbol.
func Generate(app *model.App, c *catalog.Catalog, outDir string) error {
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

	indexed := uirules.RowWidgets(app.UI, app.Symbols)
	wrapped := uirules.WrapperWidgets(app)
	for _, comp := range app.UI {
		if err := writeWidget(comp, app.Symbols, c, pagesDir, widgetsDir, tmpl, indexed, wrapped); err != nil {
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

func writeWidget(comp model.UIComponent, symbols model.SymbolTable, c *catalog.Catalog, pagesDir, widgetsDir string, tmpl *template.Template, indexed, wrapped map[string]bool) error {
	className := dart.WidgetClass(comp.Name)
	fileName := dart.SnakeCase(comp.Name) + ".dart"
	dir := widgetsDir
	if dart.IsPageName(comp.Name) {
		dir = pagesDir
	}

	// A referenced widget that has a wrapper of its own arrives as a slot: this
	// widget declares a Widget parameter for it and renders it as given.
	// Everything else it embeds itself, and takes what that child needs.
	slots, embedded := splitRefs(uirules.ReferencedWidgets(comp, symbols), wrapped)
	r := &renderer{
		symbols:     symbols,
		catalog:     c,
		ownEvents:   eventsOf(comp.Name, symbols),
		childEvents: childEventParams(embedded, symbols),
		indexed:     indexed,
		isRow:       indexed[comp.Name],
		slots:       nameSet(slots),
	}

	vars := ownVariables(comp, embedded, symbols)
	r.aliases = callbackNames(comp.Variables)
	r.widgetVars = widgetValuedVars(vars)
	r.forwarded = forwardedVariables(embedded, symbols)

	var params strings.Builder
	var fields strings.Builder
	for _, v := range vars {
		// A callback is optional, because a dumb widget must still render with
		// nothing wired to it. A value is required: rendering without it would
		// mean inventing one.
		dartType := dart.VariableType(v.Type)
		if strings.HasSuffix(dartType, "?") {
			params.WriteString(fmt.Sprintf(", this.%s", v.Name))
		} else {
			params.WriteString(fmt.Sprintf(", required this.%s", v.Name))
		}
		fields.WriteString(fmt.Sprintf("\n  final %s %s;", dartType, v.Name))
	}
	if r.isRow {
		params.WriteString(", required this.index")
		fields.WriteString("\n  final int index;")
	}
	// A slot is required: a widget with a hole where a child should be renders
	// nothing where the spec said something.
	for _, name := range slots {
		params.WriteString(fmt.Sprintf(", required this.%s", name))
		fields.WriteString(fmt.Sprintf("\n  final Widget %s;", name))
	}
	// A row is built by whoever knows what an element is, which is the wrapper.
	// The widget takes the builder and stays dumb: it knows how many rows and
	// where they go, and nothing about what is in one.
	for _, name := range uirules.ItemBuilders(comp) {
		params.WriteString(fmt.Sprintf(", required this.%s", name))
		fields.WriteString(fmt.Sprintf("\n  final %s %s;", itemBuilderType, name))
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
		Imports:   collectImports(embedded, dir),
		Root:      r.renderTopLevel(comp),
	}

	path := filepath.Join(dir, fileName)
	return dart.ExecuteTemplate(tmpl, "widget.dart.tmpl", path, data)
}

// renderer carries everything the render pass needs: the symbol table, the
// catalog, and the callback parameters this widget exposes.
type renderer struct {
	symbols model.SymbolTable
	catalog *catalog.Catalog

	// ownEvents are events declared on this widget, e.g. "onPressed". They are
	// exposed under their own name and bound to this widget's root.
	ownEvents []string

	// widgetVars are this widget's variables that hold a widget rather than a
	// value, so they render as themselves instead of as Text.
	widgetVars map[string]bool

	// forwarded maps a referenced widget to the variables it needs, which this
	// widget takes as its own and hands down when it instantiates it.
	forwarded map[string][]model.Variable

	// indexed names the widgets rendered once per list element, and isRow says
	// whether this one is.
	indexed map[string]bool
	isRow   bool

	// aliases are the names this widget's spec gave its own handlers, which are
	// what a behavior addresses and what a test taps.
	aliases map[string]bool

	// slots names the referenced widgets this widget takes as parameters rather
	// than instantiating, because each has a wrapper that wires it.
	slots map[string]bool

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

// splitRefs divides the widgets this one references into the ones that arrive
// as slots and the ones it instantiates itself.
func splitRefs(refs []string, wrapped map[string]bool) (slots, embedded []string) {
	for _, name := range refs {
		if wrapped[name] {
			slots = append(slots, name)
			continue
		}
		embedded = append(embedded, name)
	}
	return slots, embedded
}

func nameSet(names []string) map[string]bool {
	out := make(map[string]bool, len(names))
	for _, name := range names {
		out[name] = true
	}
	return out
}

// eventsOf returns the events declared on widget that need a parameter of
// their own, in a stable order.
//
// An event the UI spec already fills with a variable is not one of them:
// `onChanged: taskToggled` means taskToggled is the checkbox's onChanged, and a
// second `onChanged` parameter beside it is a parameter the widget renders
// nowhere.
func eventsOf(widget string, symbols model.SymbolTable) []string {
	filled := filledProps(symbols.Widgets[widget])
	var out []string
	for _, path := range order.Keys(symbols.Events) {
		ref := symbols.Events[path]
		if ref.Widget != widget || filled[ref.Event] {
			continue
		}
		out = append(out, ref.Event)
	}
	return dart.UniqueStrings(out)
}

// callbackNames is the set of names this widget's spec gave to handlers.
func callbackNames(vars []model.Variable) map[string]bool {
	out := make(map[string]bool, len(vars))
	for _, v := range vars {
		if catalog.PropType(v.Type).IsCallback() {
			out[v.Name] = true
		}
	}
	return out
}

// filledProps names the props a widget's own variables already fill.
func filledProps(comp model.UIComponent) map[string]bool {
	out := make(map[string]bool, len(comp.Variables))
	for _, v := range comp.Variables {
		if v.Prop != "" {
			out[v.Prop] = true
		}
	}
	return out
}

// childEventParams names the forwarded parameter for every event of every
// referenced widget: incrementButton.onPressed becomes incrementButtonOnPressed.
func childEventParams(refs []string, symbols model.SymbolTable) map[string]map[string]string {
	out := make(map[string]map[string]string)
	for _, name := range refs {
		events := eventsOf(name, symbols)
		if len(events) == 0 {
			continue
		}
		params := make(map[string]string, len(events))
		for _, event := range events {
			params[event] = dart.ForwardedCallbackParam(name, event)
		}
		out[name] = params
	}
	return out
}

func collectImports(refs []string, currentDir string) string {
	if len(refs) == 0 {
		return ""
	}
	var b strings.Builder
	for _, name := range refs {
		rel := relativeImportPath(currentDir, name)
		b.WriteString(fmt.Sprintf("\nimport '%s/%s.dart';", rel, dart.SnakeCase(name)))
	}
	return b.String()
}

func relativeImportPath(currentDir, targetName string) string {
	currentBase := filepath.Base(currentDir)
	targetBase := "widgets"
	if dart.IsPageName(targetName) {
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

func (r *renderer) renderTopLevel(comp model.UIComponent) string {
	return r.renderComponent(comp, true)
}

func (r *renderer) renderComponent(comp model.UIComponent, topLevel bool) string {
	if sym, ok := r.catalog.Find(comp.Kind); ok {
		return r.renderCatalogWidget(comp, sym, topLevel)
	}
	// Custom widget reference.
	return r.renderWidgetRef(comp.Name)
}

// renderWidgetRef instantiates another declared widget, forwarding the
// callbacks this widget exposes on its behalf.
// rootKey is how a test finds this widget. A row carries its index, so the
// rows of one list are told apart both by the framework and by a scenario
// saying `.first` or `.last`.
func (r *renderer) rootKey(name string) string {
	if r.isRow {
		return fmt.Sprintf("key: Key('%s_$index')", name)
	}
	return fmt.Sprintf("key: const Key(%s)", dart.DartStringLiteral(name))
}

func (r *renderer) renderWidgetRef(name string) string {
	// A slot is rendered as the parameter it arrived in. What fills it is the
	// child's own wrapper, chosen one level up.
	if r.slots[name] {
		return name
	}

	var args []string
	if r.indexed[name] {
		args = append(args, "index: index")
	}
	// A referenced widget's variables are passed straight through under their
	// own names: the same name means the same value, and the wrapper above
	// supplies it once for the whole page.
	for _, v := range r.forwarded[name] {
		args = append(args, fmt.Sprintf("%s: %s", v.Name, v.Name))
	}
	params := r.childEvents[name]
	for _, event := range order.Keys(params) {
		args = append(args, fmt.Sprintf("%s: %s", event, params[event]))
	}
	if len(args) == 0 {
		return fmt.Sprintf("const %s()", dart.WidgetClass(name))
	}
	return fmt.Sprintf("%s(%s)", dart.WidgetClass(name), strings.Join(args, ", "))
}

func (r *renderer) renderCatalogWidget(comp model.UIComponent, sym catalog.Symbol, topLevel bool) string {
	var args []string

	switch {
	case topLevel:
		args = append(args, r.rootKey(comp.Name))
	default:
		// An inner widget the spec named an event on is something a test has to
		// tap, and a test finds a widget by key. The name it was given is the
		// key, because that name is what a behavior addresses it by.
		if alias := r.aliasOn(comp); alias != "" {
			args = append(args, r.rootKey(alias))
		}
	}

	if out, ok := r.renderDynamicList(comp, sym, args); ok {
		return out
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

	args = append(args, r.missingCallbackArgs(comp, topLevel)...)

	if len(args) == 1 {
		return fmt.Sprintf("%s(%s)", sym.FlutterWidget, args[0])
	}
	return fmt.Sprintf("%s(\n%s\n)", sym.FlutterWidget, dart.Indent(strings.Join(args, ",\n")))
}

// missingCallbackArgs supplies the required arguments the spec did not declare.
// A widget must still compile with nothing wired, so an undeclared callback is
// null unless the behaviors name it, in which case the widget takes it as a
// parameter for a wrapper to fill.
func (r *renderer) missingCallbackArgs(comp model.UIComponent, topLevel bool) []string {
	var args []string
	for _, cb := range requiredCallbacks(comp.Kind) {
		if _, ok := comp.Props[cb]; ok {
			continue
		}
		if topLevel && r.exposesEvent(cb) {
			args = append(args, fmt.Sprintf("%s: %s", cb, cb))
			continue
		}
		args = append(args, fmt.Sprintf("%s: null", cb))
	}
	return args
}

// aliasOn returns the name this widget's callback prop was given, if the spec
// gave it one. Props are walked in catalog order so the key of a widget with
// two named handlers does not depend on map iteration.
func (r *renderer) aliasOn(comp model.UIComponent) string {
	sym, ok := r.catalog.Find(comp.Kind)
	if !ok {
		return ""
	}
	for _, prop := range catalogPropOrder(sym, comp.Props) {
		if !r.catalog.PropType(comp.Kind, prop).IsCallback() {
			continue
		}
		if name, ok := comp.Props[prop].(string); ok && r.aliases[name] {
			return name
		}
	}
	return ""
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

	for _, p := range sym.Props {
		if _, ok := props[p.Name]; ok && !seen[p.Name] {
			ordered = append(ordered, p.Name)
			seen[p.Name] = true
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

func (r *renderer) renderDefaultProp(comp model.UIComponent, sym catalog.Symbol) string {
	prop := sym.DefaultProp
	if prop == catalog.PropChild && len(comp.Children) > 0 {
		return fmt.Sprintf("%s: %s", prop, r.renderComponent(comp.Children[0], false))
	}
	if prop == catalog.PropChildren && len(comp.Children) > 0 {
		return fmt.Sprintf("%s: %s", prop, r.renderChildrenList(comp.Children))
	}
	if val, ok := comp.Props[prop]; ok {
		if prop == catalog.PropIcon {
			return r.renderIconProp(comp.Kind, val)
		}
		expectsWidget := r.catalog.WidgetProp(comp.Kind, prop)
		if prop == catalog.PropData {
			return r.renderPropValue(val, expectsWidget)
		}
		return fmt.Sprintf("%s: %s", prop, r.renderPropValue(val, expectsWidget))
	}
	return ""
}

// renderIconProp renders an `icon` prop whose value names the icon vocabulary.
// The name is looked up rather than rewritten, so what the catalog calls
// `icons.hidden` becomes whatever this target spells it. Validation has already
// rejected an unknown name by the time this runs.
//
// The icon widget takes the icon positionally; everything else takes an icon
// widget under the prop name.
func (r *renderer) renderIconProp(kind string, val any) string {
	name, ok := val.(string)
	if !ok {
		return ""
	}
	icon, ok := r.catalog.FindIcon(name)
	if !ok {
		return ""
	}
	if kind == "icon" {
		return icon.FlutterIcon
	}
	return fmt.Sprintf("%s: const Icon(%s)", catalog.PropIcon, icon.FlutterIcon)
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
			comp := model.UIComponent{
				Name:  kind,
				Kind:  kind,
				Props: props,
			}
			return r.renderComponent(comp, false)
		}
	}
	return r.renderPropValue(val, expectsWidget)
}

func (r *renderer) renderChildrenList(children []model.UIComponent) string {
	var parts []string
	for _, child := range children {
		parts = append(parts, r.renderComponent(child, false))
	}
	return fmt.Sprintf("[\n%s\n]", dart.Indent(strings.Join(parts, ",\n")))
}

func (r *renderer) renderPropValue(val any, expectsWidget bool) string {
	switch v := val.(type) {
	case string:
		if expectsWidget {
			if sym, ok := r.symbols.Lookup(v); ok && sym.Kind == "widget" {
				return r.renderWidgetRef(v)
			}
			if r.widgetVars[v] {
				return v
			}
			if uirules.IsVariableIdentifier(v) && !r.catalog.IsKnown(v) {
				return fmt.Sprintf("Text(%s)", v)
			}
			return fmt.Sprintf("const Text(%s)", dart.DartStringLiteral(v))
		}
		if uirules.IsVariableIdentifier(v) && !r.catalog.IsKnown(v) {
			return v
		}
		return dart.DartStringLiteral(v)
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
			comp := model.UIComponent{
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
	return fmt.Sprintf("[\n%s\n]", dart.Indent(strings.Join(parts, ",\n")))
}

// widgetValuedVars picks out the variables that hold a widget, so they render
// as themselves rather than wrapped in Text. Symbol resolution typed them from
// the behaviors: a scenario saying `homePage.homeContent should be emptyState`
// is what makes homeContent a widget, since the UI spec alone cannot tell a
// widget name from a value.
func widgetValuedVars(vars []model.Variable) map[string]bool {
	out := make(map[string]bool)
	for _, v := range vars {
		if v.Type == model.TypeWidget {
			out[v.Name] = true
		}
	}
	return out
}

// renderDynamicList renders a listView that names a collection. The spec says
// what it lists and what one element looks like; Flutter wants a count and a
// closure, and this is where the two are reconciled. The spec never spells
// `itemCount` or `itemBuilder`, and the catalog never spells `.builder`.
//
// The builder is a parameter rather than a closure written here. What a row
// shows is a fact about the elements, and the generator does not know one:
// `taskTitle` is a bare variable and `task.description` is a model field, and
// nothing in the specs joins them. The wrapper does know, so it passes the
// builder in, the same way it passes every other value that reaches a store.
func (r *renderer) renderDynamicList(comp model.UIComponent, sym catalog.Symbol, args []string) (string, bool) {
	items, ok := comp.Props[catalog.PropItems].(string)
	if !ok {
		return "", false
	}
	item, ok := comp.Props[catalog.PropItem]
	if !ok {
		return "", false
	}

	builder, ok := item.(string)
	if !ok {
		return "", false
	}
	args = append(args,
		fmt.Sprintf("itemCount: %s.length", items),
		fmt.Sprintf("itemBuilder: %s", builder),
	)
	return fmt.Sprintf("%s.builder(\n%s\n)", sym.FlutterWidget, strings.Join(args, ",\n")), true
}

// itemBuilderType is the signature of a row builder: the widget calls it with
// the row index, and the wrapper decides what that row shows.
const itemBuilderType = "Widget Function(BuildContext, int)"

// ownVariables is every variable this widget declares as a parameter: the ones
// in its own tree, plus the ones the widgets it embeds need. A referenced
// widget is instantiated here, so whatever it requires has to arrive here too.
func ownVariables(comp model.UIComponent, refs []string, symbols model.SymbolTable) []model.Variable {
	vars := append([]model.Variable(nil), comp.Variables...)
	for _, name := range refs {
		vars = append(vars, symbols.Widgets[name].Variables...)
	}
	return model.UniqueVariables(vars)
}

// forwardedVariables maps each referenced widget to the variables it needs.
func forwardedVariables(refs []string, symbols model.SymbolTable) map[string][]model.Variable {
	out := make(map[string][]model.Variable, len(refs))
	for _, name := range refs {
		if vars := model.UniqueVariables(symbols.Widgets[name].Variables); len(vars) > 0 {
			out[name] = vars
		}
	}
	return out
}
