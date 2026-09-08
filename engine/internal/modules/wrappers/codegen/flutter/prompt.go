package flutter

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
)

// BuildWrapperPrompt assembles the prompt sent to the LLM for one wrapper.
//
// It carries every scenario the wrapper is responsible for, not just one. A
// page wrapper is the only widget in the composed tree, so it wires the whole
// subtree: showing it a single scenario left it guessing at the rest, and a
// page with two buttons came back with one of them wired and the other dead.
func BuildWrapperPrompt(app *ir.IR, plan Plan, outDir string) (string, error) {
	scenarios := scenariosForWidget(app, plan.WidgetName)
	if len(scenarios) == 0 {
		return "", fmt.Errorf("no scenario references widget %q", plan.WidgetName)
	}

	var b strings.Builder
	b.WriteString("You are generating Flutter code that connects existing generated widgets to existing generated Cubits.\n")
	b.WriteString("Do not modify the dumb widget or cubit classes. Import them and instantiate the dumb widget.\n")
	b.WriteString("The dumb widget exposes every value and every callback it needs as a constructor parameter.\n")
	b.WriteString("Wire the behavior by passing those parameters. Do not reimplement the widget, do not wrap it\n")
	b.WriteString("in a GestureDetector or InkWell, and do not add extra classes to the file.\n")
	b.WriteString("Pass every callback parameter the widget declares. A parameter you leave out is a dead control.\n")
	b.WriteString("Business rules live in the Cubit. Call its methods; never call emit from a widget.\n")
	b.WriteString("Use flutter_bloc. Prefer BlocSelector. Read Cubits with context.read.\n")
	b.WriteString("Use relative imports (../widgets/, ../pages/, ../stores/), never package: imports of this project.\n")
	b.WriteString("Make the code compile and satisfy every behavior below.\n")
	b.WriteString("Return only the Dart code, wrapped in a ```dart ... ``` fence.\n\n")

	b.WriteString("=== Behavior scenarios ===\n")
	for _, s := range scenarios {
		b.WriteString(fmt.Sprintf("ID: %s\n", s.ID))
		b.WriteString(fmt.Sprintf("Description: %s\n", s.Description))
		if s.Given != nil {
			b.WriteString(fmt.Sprintf("Given: %s %s %s\n", s.Given.Target, s.Given.Op, s.Given.Value))
		}
		if s.When != "" {
			b.WriteString(fmt.Sprintf("When: %s\n", s.When))
		}
		if s.Then != nil {
			b.WriteString(fmt.Sprintf("Then: %s %s %s\n", s.Then.Target, s.Then.Op, s.Then.Value))
		}
		b.WriteString("\n")
	}

	if bindings := bindingsForWidget(app, plan.WidgetName); len(bindings) > 0 {
		b.WriteString("=== Widget events and the store actions they run ===\n")
		for _, binding := range bindings {
			b.WriteString(fmt.Sprintf("%s -> %s.%s\n", binding.FullPath(), binding.Store, binding.Action))
		}
		b.WriteString("\n")
	}

	b.WriteString("=== Generated Cubit and state classes ===\n")
	for _, store := range app.Stores {
		if err := appendStoreCode(&b, outDir, store); err != nil {
			return "", err
		}
	}
	b.WriteString("\n")

	b.WriteString("=== Dumb widget to wrap ===\n")
	if err := appendWidgetCode(&b, outDir, plan.WidgetName); err != nil {
		return "", err
	}
	b.WriteString("\n")

	b.WriteString("=== Instructions ===\n")
	b.WriteString(fmt.Sprintf("Create a stateless wrapper widget for %q.\n", plan.WidgetName))
	b.WriteString("Wire it by passing the constructor parameters of the dumb widget shown above.\n")
	b.WriteString(fmt.Sprintf("Name the wrapper class %s and declare exactly one class.\n", plan.ClassName))
	b.WriteString("The file goes in lib/wrappers, so the dumb widget is one directory up.\n")

	return b.String(), nil
}

// scenariosForWidget returns every scenario that names the widget or any widget
// it embeds, in spec order. A page is responsible for its whole subtree.
func scenariosForWidget(app *ir.IR, widgetName string) []ir.BehaviorScenario {
	owned := widgetSubtree(app, widgetName)

	var out []ir.BehaviorScenario
	for _, s := range app.Behaviors {
		if scenarioTouches(app, s, owned) {
			out = append(out, s)
		}
	}
	return out
}

// bindingsForWidget returns the widget-event bindings the wrapper must wire,
// including those of the widgets it embeds.
func bindingsForWidget(app *ir.IR, widgetName string) []ir.Binding {
	owned := widgetSubtree(app, widgetName)

	var out []ir.Binding
	for _, binding := range app.Symbols.Bindings {
		if owned[binding.Widget] {
			out = append(out, binding)
		}
	}
	return out
}

// widgetSubtree returns the widget and every declared widget reachable from it.
func widgetSubtree(app *ir.IR, widgetName string) map[string]bool {
	owned := map[string]bool{widgetName: true}

	comp := shared.FindComponent(app.UI, widgetName)
	if comp == nil {
		return owned
	}

	// Only a page composes other declared widgets today, and it does so by
	// name, so a single pass over the props finds them.
	var walk func(raw any)
	walk = func(raw any) {
		switch v := raw.(type) {
		case string:
			if sym, ok := app.Symbols.Lookup(v); ok && sym.Kind == "widget" {
				owned[v] = true
			}
		case map[string]any:
			for key, val := range v {
				if sym, ok := app.Symbols.Lookup(key); ok && sym.Kind == "widget" {
					owned[key] = true
				}
				walk(val)
			}
		case []any:
			for _, item := range v {
				walk(item)
			}
		}
	}
	walk(comp.Props)
	return owned
}

func scenarioTouches(app *ir.IR, s ir.BehaviorScenario, owned map[string]bool) bool {
	if s.Then != nil {
		if w, _, ok := splitWidgetRef(app, s.Then.Target); ok && owned[w] {
			return true
		}
	}
	if s.When != "" {
		if w, _, ok := splitWidgetRef(app, s.When); ok && owned[w] {
			return true
		}
	}
	return false
}

func findScenario(app *ir.IR, id string) (ir.BehaviorScenario, error) {
	for _, s := range app.Behaviors {
		if s.ID == id {
			return s, nil
		}
	}
	return ir.BehaviorScenario{}, fmt.Errorf("scenario %q not found", id)
}

func splitWidgetRef(app *ir.IR, ref string) (string, string, bool) {
	parts := strings.SplitN(ref, ".", 2)
	if len(parts) != 2 {
		return "", "", false
	}
	if sym, ok := app.Symbols.Lookup(parts[0]); !ok || sym.Kind != "widget" {
		return "", "", false
	}
	return parts[0], parts[1], true
}

func appendStoreCode(b *strings.Builder, outDir string, store ir.Store) error {
	base := shared.StoreBaseName(store.Name)
	stateFile := filepath.Join(outDir, "lib", "stores", shared.SnakeCase(base)+"_state.dart")
	cubitFile := filepath.Join(outDir, "lib", "stores", shared.SnakeCase(base)+"_cubit.dart")

	stateCode, err := os.ReadFile(stateFile)
	if err != nil {
		return fmt.Errorf("read state file: %w", err)
	}
	cubitCode, err := os.ReadFile(cubitFile)
	if err != nil {
		return fmt.Errorf("read cubit file: %w", err)
	}

	b.WriteString(fmt.Sprintf("// %s\n%s\n", stateFile, string(stateCode)))
	b.WriteString(fmt.Sprintf("// %s\n%s\n", cubitFile, string(cubitCode)))
	return nil
}

func appendWidgetCode(b *strings.Builder, outDir, widgetName string) error {
	dir := "widgets"
	if shared.IsPageName(widgetName) {
		dir = "pages"
	}
	widgetFile := filepath.Join(outDir, "lib", dir, shared.SnakeCase(widgetName)+".dart")
	code, err := os.ReadFile(widgetFile)
	if err != nil {
		return fmt.Errorf("read widget file %s: %w", widgetFile, err)
	}
	b.WriteString(fmt.Sprintf("// %s\n%s\n", widgetFile, string(code)))
	return nil
}
