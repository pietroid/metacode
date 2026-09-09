package behaviorflutter

import (
	"fmt"
	"sort"
	"strings"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/ui/rules"
)

// tree is what a wrapper has to know about the widgets around it: which of them
// have wrappers of their own, and which are built once per row. Both are rules
// about the UI spec, asked once per run so every wrapper agrees.
type tree struct {
	wrapped map[string]bool
	indexed map[string]bool
}

func treeOf(app *model.App) tree {
	return tree{
		wrapped: uirules.WrapperWidgets(app),
		indexed: uirules.RowWidgets(app.UI, app.Symbols),
	}
}

// wrapperBody renders one wrapper: it instantiates the generated dumb widget
// and fills the parameters that reach the store, plus the slot for every child
// that has a wrapper of its own.
//
// It does not re-render the widget tree and it does not build another widget's
// children: the generated widget already exposes a parameter per variable, per
// event and per wired child, put there for this purpose. A wrapper is one
// constructor call, which is what keeps the shape of the tree in the generated
// widgets. See docs/decisions.md, "A widget that needs wiring is reached
// through its own wrapper".
func wrapperBody(app *model.App, wrapper Wrapper, t tree) (string, error) {
	comp := dart.FindComponent(app.UI, wrapper.WidgetName)
	if comp == nil {
		return "", fmt.Errorf("widget %q not found in the UI spec", wrapper.WidgetName)
	}
	if len(app.Stores) == 0 {
		return "", fmt.Errorf("wrapper %q has no store to wire", wrapper.WidgetName)
	}
	// One store, checked in the resolve stage: see datarules.CheckSupported.
	store := app.Stores[0]

	args, selector, refs := wrapperArgs(app, *comp, store, t)
	widget := fmt.Sprintf("%s(\n%s,\n)", dart.WidgetClass(comp.Name), dart.IndentBy(strings.Join(args, ",\n"), 2))

	body := widget
	if selector != "" {
		// A value read from the store has to rebuild when the store changes.
		body = fmt.Sprintf("BlocSelector<%s, %s, String>(\n  selector: (state) => %s,\n  builder: (context, %s) => %s,\n)",
			dart.CubitClass(store.Name), dart.StateClass(store.Name), selector, selectorVariable, dart.IndentLines(widget, 2))
	}

	return fmt.Sprintf(`import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
%s
class %s extends StatelessWidget {
  const %s({super.key%s});
%s
  @override
  Widget build(BuildContext context) {
    return %s;
  }
}
`, wrapperImports(*comp, store, selector, refs), wrapper.ClassName, wrapper.ClassName,
		rowParam(t.indexed[comp.Name]), rowField(t.indexed[comp.Name]), dart.IndentLines(body, 4)), nil
}

// A row wrapper is built once per element and told which one it is, so it can
// read that row and so the widget below it keys itself by the same index. See
// docs/decisions.md, "A row knows which row it is".
func rowParam(isRow bool) string {
	if !isRow {
		return ""
	}
	return ", required this.index"
}

func rowField(isRow bool) string {
	if !isRow {
		return ""
	}
	return "  final int index;\n"
}

// selectorVariable is the name the BlocSelector builder binds the selected
// value to. There is one selector per wrapper, so one name is enough.
const selectorVariable = "value"

// wrapperArgs is the argument list for the dumb widget: the store expression it
// has to select on, if any, and every file the arguments name.
func wrapperArgs(app *model.App, comp model.UIComponent, store model.Store, t tree) ([]string, string, []string) {
	b := &argBuilder{app: app, comp: comp, store: store, tree: t}
	if t.indexed[comp.Name] {
		b.args = append(b.args, "index: index")
	}
	b.addVariables()
	b.addSlots()
	b.addItemBuilders()
	b.addEvents()
	return b.args, b.selector, b.refs
}

// argBuilder accumulates one wrapper's arguments, together with the store
// expression and the imports they imply.
type argBuilder struct {
	app   *model.App
	comp  model.UIComponent
	store model.Store
	tree  tree

	args     []string
	selector string
	refs     []string
}

// addVariables fills the widget's own variables: a value from the store when
// the scenarios say where it comes from, a callback from the binding that
// names its action, and a widget from the widget a scenario says goes there.
func (b *argBuilder) addVariables() {
	bound := storeBackedVariables(b.app, b.comp.Name, b.store)
	for _, v := range model.UniqueVariables(b.comp.Variables) {
		switch {
		case isCallbackType(v.Type):
			if binding, ok := b.app.Symbols.BindingFor(b.comp.Name, v.Name); ok {
				b.args = append(b.args, fmt.Sprintf("%s: %s => %s", v.Name, callbackHead(v.Type), b.action(binding)))
			}
		case v.Type == model.TypeWidget:
			b.args = append(b.args, fmt.Sprintf("%s: %s", v.Name, b.widgetFor(v.Name)))
		default:
			expression, ok := bound[v.Name]
			if !ok {
				// No scenario says where this value comes from. A placeholder
				// of the right type compiles, and the scenario that needed it
				// fails with something a reader can act on rather than a
				// missing parameter.
				b.args = append(b.args, fmt.Sprintf("%s: %s", v.Name, dart.VariablePlaceholder(v.Type)))
				continue
			}
			b.selector = expression
			b.args = append(b.args, fmt.Sprintf("%s: %s", v.Name, selectorVariable))
		}
	}
}

// addSlots fills the parameter the widget declares for every child that has a
// wrapper: the child's wrapper, and nothing about what is inside it.
func (b *argBuilder) addSlots() {
	for _, name := range uirules.ReferencedWidgets(b.comp, b.app.Symbols) {
		if !b.tree.wrapped[name] {
			continue
		}
		b.args = append(b.args, fmt.Sprintf("%s: %s", name, b.child(name)))
	}
}

// addItemBuilders fills a list's row builder. The row is a widget like any
// other, so the builder hands it the index and stops there.
func (b *argBuilder) addItemBuilders() {
	for _, name := range uirules.ItemBuilders(b.comp) {
		b.args = append(b.args, fmt.Sprintf("%s: (context, index) => %s", name, b.child(name)))
	}
}

// addEvents wires the events the widget exposes under their own name, which is
// every bound event no variable already fills.
func (b *argBuilder) addEvents() {
	// A variable already fills its prop under its own name, and that name is
	// what a binding on it points at.
	filled := make(map[string]bool)
	for _, v := range b.comp.Variables {
		filled[v.Name] = true
	}
	for _, binding := range b.app.Symbols.Bindings {
		if binding.Widget != b.comp.Name || filled[binding.Param] {
			continue
		}
		b.args = append(b.args, fmt.Sprintf("%s: () => %s", binding.Param, b.action(binding)))
	}
}

func (b *argBuilder) action(binding model.Binding) string {
	return fmt.Sprintf("context.read<%s>().%s()", dart.CubitClass(binding.Store), binding.Action)
}

// child renders the expression that fills a slot: the child's wrapper when it
// has one, and the child itself when there is nothing to wire in it.
func (b *argBuilder) child(name string) string {
	if !b.tree.wrapped[name] {
		b.refs = append(b.refs, dart.WidgetFile(name))
		return fmt.Sprintf("const %s()", dart.WidgetClass(name))
	}
	b.refs = append(b.refs, dart.WrapperFile(name))
	if b.tree.indexed[name] {
		return fmt.Sprintf("%s(index: index)", dart.WrapperClass(name))
	}
	return fmt.Sprintf("const %s()", dart.WrapperClass(name))
}

// widgetFor fills a variable that holds a widget with the widget a scenario
// says belongs there. A page whose content swaps between an empty state and a
// list is the case: which one is showing is behavior, so the scaffold puts the
// first one a scenario names and the implement stage decides between them.
func (b *argBuilder) widgetFor(variable string) string {
	target := b.comp.Name + "." + variable
	for _, scenario := range b.app.Behaviors {
		if scenario.Then == nil || scenario.Then.Target != target {
			continue
		}
		if _, ok := b.app.Symbols.Widgets[scenario.Then.Value]; ok {
			return b.child(scenario.Then.Value)
		}
	}
	return dart.VariablePlaceholder(model.TypeWidget)
}

// isCallbackType reports whether a variable holds a callback, whatever it
// carries.
func isCallbackType(t string) bool {
	return strings.HasPrefix(t, "callback")
}

// callbackHead is the parameter list of the closure that fills a callback: a
// callback carrying a value is handed one, and the wrapper ignores it because
// the action it runs is named by the spec, not by what the widget reports.
func callbackHead(t string) string {
	if t == "callback" {
		return "()"
	}
	return "(_)"
}

func wrapperImports(comp model.UIComponent, store model.Store, selector string, refs []string) string {
	imports := []string{
		"import '" + relativeLibImport(dart.WidgetFile(comp.Name)) + "';",
		"import '" + relativeLibImport(dart.CubitFile(store.Name)) + "';",
	}
	if selector != "" {
		imports = append(imports, "import '"+relativeLibImport(dart.StateFile(store.Name))+"';")
	}
	for _, ref := range dart.UniqueStrings(refs) {
		imports = append(imports, "import '"+relativeLibImport(ref)+"';")
	}
	sort.Strings(imports)
	return strings.Join(imports, "\n") + "\n"
}

// relativeLibImport rewrites a lib-relative path as an import from inside
// lib/wrappers/.
func relativeLibImport(libPath string) string {
	return "../" + dart.LibImport(libPath)
}

// storeBackedVariables works out which of a widget's variables display a store
// field, by reading the scenarios that assert on them: "given
// counterStore.value is 5, then homePage.counterValue is 5" says counterValue
// shows counterStore.value.
func storeBackedVariables(app *model.App, widget string, store model.Store) map[string]string {
	bound := make(map[string]string)
	storeNames := map[string]bool{store.Name: true, dart.StoreBaseName(store.Name): true}

	for _, scenario := range app.Behaviors {
		if scenario.Then == nil || scenario.Given == nil {
			continue
		}
		if !strings.HasPrefix(scenario.Then.Target, widget+".") {
			continue
		}
		root, field := model.SplitRef(scenario.Given.Target)
		if !storeNames[root] || field == "" {
			continue
		}
		// The scenario asserts the widget shows what the store holds, so the
		// two values match: that is what makes it a binding rather than a
		// transformation this engine cannot derive.
		if scenario.Then.Value == scenario.Given.Value {
			bound[strings.TrimPrefix(scenario.Then.Target, widget+".")] = fmt.Sprintf("state.%s.toString()", field)
		}
	}
	return bound
}
