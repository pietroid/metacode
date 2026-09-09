package behaviorflutter

import (
	"fmt"
	"strings"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
)

// wrapperBody renders one wrapper: it instantiates the generated dumb widget
// and passes it the values and callbacks that reach the store.
//
// It does not re-render the widget tree: the generated widget already exposes a
// parameter per variable and a parameter per event, put there for this purpose.
// See docs/decisions.md, "A wrapper composes the dumb widget".
func wrapperBody(app *model.App, wrapper Wrapper) (string, error) {
	comp := dart.FindComponent(app.UI, wrapper.WidgetName)
	if comp == nil {
		return "", fmt.Errorf("widget %q not found in the UI spec", wrapper.WidgetName)
	}
	if len(app.Stores) == 0 {
		return "", fmt.Errorf("wrapper %q has no store to wire", wrapper.WidgetName)
	}
	// One store, checked in the resolve stage: see datarules.CheckSupported.
	store := app.Stores[0]

	args, selector := wrapperArgs(app, *comp, store)
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
  const %s({super.key});

  @override
  Widget build(BuildContext context) {
    return %s;
  }
}
`, wrapperImports(app, *comp, store, selector), wrapper.ClassName, wrapper.ClassName, dart.IndentLines(body, 4)), nil
}

// selectorVariable is the name the BlocSelector builder binds the selected
// value to. There is one selector per wrapper, so one name is enough.
const selectorVariable = "value"

// wrapperArgs is the argument list for the dumb widget, and the store
// expression the wrapper has to select on, if any.
func wrapperArgs(app *model.App, comp model.UIComponent, store model.Store) ([]string, string) {
	var args []string
	selector := ""

	bound := storeBackedVariables(app, comp.Name, store)
	for _, name := range dart.UniqueStrings(comp.Variables) {
		expression, ok := bound[name]
		if !ok {
			// No scenario says where this value comes from. An empty string
			// compiles, and the scenario that needed it fails with something a
			// reader can act on rather than a missing parameter.
			args = append(args, fmt.Sprintf("%s: ''", name))
			continue
		}
		selector = expression
		args = append(args, fmt.Sprintf("%s: %s", name, selectorVariable))
	}

	for _, binding := range app.Symbols.Bindings {
		param := binding.Event
		if binding.Widget != comp.Name {
			param = dart.ForwardedCallbackParam(binding.Widget, binding.Event)
		}
		args = append(args, fmt.Sprintf("%s: () => context.read<%s>().%s()",
			param, dart.CubitClass(binding.Store), binding.Action))
	}

	return args, selector
}

func wrapperImports(app *model.App, comp model.UIComponent, store model.Store, selector string) string {
	imports := []string{
		"import '" + relativeLibImport(dart.WidgetFile(comp.Name)) + "';",
		"import '" + relativeLibImport(dart.CubitFile(store.Name)) + "';",
	}
	if selector != "" {
		imports = append(imports, "import '"+relativeLibImport(dart.StateFile(store.Name))+"';")
	}
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
