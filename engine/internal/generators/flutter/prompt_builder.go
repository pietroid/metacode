// Package flutter implements AI-assisted code generation for Flutter projects.
package flutter

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
)

// BuildWrapperPrompt assembles the prompt sent to the LLM for a wrapper task.
// It includes the behavior scenario, the generated Cubit and state classes, the
// dumb widget code, and explicit constraints.
func BuildWrapperPrompt(app *ir.IR, task PromptTask, outDir string) (string, error) {
	scenario, err := findScenario(app, task.ScenarioID)
	if err != nil {
		return "", err
	}

	widgetName, member, err := widgetAndMemberForTask(app, scenario, task)
	if err != nil {
		return "", err
	}

	var b strings.Builder
	b.WriteString("You are generating Flutter code that connects existing generated widgets to existing generated Cubits.\n")
	b.WriteString("Do not modify the dumb widget or cubit classes. Import them.\n")
	b.WriteString("Use flutter_bloc. Prefer BlocSelector.\n")
	b.WriteString("Make the code compile and satisfy this behavior.\n")
	b.WriteString("Return only the Dart code, wrapped in a ```dart ... ``` fence.\n\n")

	b.WriteString("=== Behavior scenario ===\n")
	b.WriteString(fmt.Sprintf("ID: %s\n", scenario.ID))
	b.WriteString(fmt.Sprintf("Description: %s\n", scenario.Description))
	if scenario.Given != nil {
		b.WriteString(fmt.Sprintf("Given: %s %s %s\n", scenario.Given.Target, scenario.Given.Op, scenario.Given.Value))
	}
	b.WriteString(fmt.Sprintf("When: %s\n", scenario.When))
	if scenario.Then != nil {
		b.WriteString(fmt.Sprintf("Then: %s %s %s\n", scenario.Then.Target, scenario.Then.Op, scenario.Then.Value))
	}
	b.WriteString("\n")

	b.WriteString("=== Generated Cubit and state classes ===\n")
	for _, store := range app.Stores {
		if err := appendStoreCode(&b, outDir, store); err != nil {
			return "", err
		}
	}
	b.WriteString("\n")

	b.WriteString("=== Dumb widget to wrap ===\n")
	if err := appendWidgetCode(&b, outDir, widgetName); err != nil {
		return "", err
	}
	b.WriteString("\n")

	b.WriteString("=== Instructions ===\n")
	b.WriteString(fmt.Sprintf("Create a stateless wrapper widget for %q.\n", widgetName))
	b.WriteString(fmt.Sprintf("Wire %q so the scenario above is satisfied.\n", member))
	b.WriteString(fmt.Sprintf("Name the wrapper class %s.\n", wrapperClassName(widgetName)))
	b.WriteString("Place the file in the lib/wrappers directory.\n")

	return b.String(), nil
}

// PromptTask is the subset of planner.Task used by the prompt builder.
type PromptTask struct {
	ScenarioID string
}

func findScenario(app *ir.IR, id string) (ir.BehaviorScenario, error) {
	for _, s := range app.Behaviors {
		if s.ID == id {
			return s, nil
		}
	}
	return ir.BehaviorScenario{}, fmt.Errorf("scenario %q not found", id)
}

func widgetAndMemberForTask(app *ir.IR, scenario ir.BehaviorScenario, task PromptTask) (string, string, error) {
	if scenario.Then != nil {
		if w, m, ok := splitWidgetRef(app, scenario.Then.Target); ok {
			return w, m, nil
		}
	}
	if scenario.When != "" {
		if w, m, ok := splitWidgetRef(app, scenario.When); ok {
			return w, m, nil
		}
	}
	return "", "", fmt.Errorf("task %q does not reference a widget", task.ScenarioID)
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

func wrapperClassName(widgetName string) string {
	return shared.PascalCase(widgetName) + "Wrapper"
}
