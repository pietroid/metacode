package implementer

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
	"github.com/pietroid/metacode/engine/internal/planner"
	"github.com/pietroid/metacode/engine/internal/runner"
)

const rules = `Rules:
- The dumb widgets, the state classes and the tests are generated from the specs. Never rewrite them.
- Business rules live in the Cubit. A widget calls Cubit methods; a widget never calls emit.
- A wrapper instantiates the dumb widget and passes its constructor parameters. Do not reimplement
  the widget, do not wrap it in a GestureDetector or InkWell, and declare exactly one class per file.
- Pass every callback parameter a dumb widget declares. A parameter left out is a dead control.
- Use flutter_bloc. Read Cubits with context.read, rebuild with BlocSelector or BlocBuilder.
- Inside lib, use relative imports (../widgets/, ../pages/, ../stores/), never package: imports of this project.
- Keep every declaration a file already has, including methods no test exercises.
- Implement the behavior described by the scenarios, not only the literal values the tests check.
  "not decrements when is 0" is a rule about every value at the floor, not about the number 0.
`

// buildImplementPrompt assembles the single request that implements the app.
func (im *Implementer) buildImplementPrompt(files []editableFile) (string, error) {
	var b strings.Builder

	b.WriteString("You are implementing a Flutter app that has already been scaffolded from a specification.\n")
	b.WriteString("The scaffolding is complete and correct: the classes, their names, and the files they live in\n")
	b.WriteString("all come from the spec. What is missing is behavior — the bodies of the store actions and the\n")
	b.WriteString("wiring between widgets and stores.\n\n")
	b.WriteString(rules)
	b.WriteString("\n")

	if err := im.writeContext(&b); err != nil {
		return "", err
	}

	if err := im.writeEditable(&b, files); err != nil {
		return "", err
	}

	writeOutputFormat(&b, files)
	return b.String(), nil
}

// buildRepairPrompt assembles a request that carries every failure of one test
// run.
func (im *Implementer) buildRepairPrompt(files []editableFile, failures []runner.Failure) (string, error) {
	var b strings.Builder

	b.WriteString("You are fixing a Flutter app whose generated tests are failing.\n")
	b.WriteString("The tests are generated from the specification and are correct by definition: make the app\n")
	b.WriteString("satisfy them. Fix the cause, not the assertion.\n\n")
	b.WriteString(rules)
	b.WriteString("\n")

	b.WriteString("=== Failing tests ===\n")
	for _, f := range failures {
		fmt.Fprintf(&b, "\n--- %s: %s ---\n", f.File, f.Name)
		if f.Message != "" {
			b.WriteString(f.Message)
			b.WriteString("\n")
		}
	}
	b.WriteString("\n")

	if err := im.writeContext(&b); err != nil {
		return "", err
	}

	if err := im.writeEditable(&b, files); err != nil {
		return "", err
	}

	writeOutputFormat(&b, files)
	b.WriteString("Return only the files you are changing. Files you leave out keep their current contents.\n")
	return b.String(), nil
}

// writeContext writes everything both requests need: the spec, the generated
// code the model must read but not change, and every test.
func (im *Implementer) writeContext(b *strings.Builder) error {
	app := im.App

	b.WriteString("=== Specification: behaviors ===\n")
	b.WriteString("Every scenario below is verified by exactly one test.\n\n")
	for _, s := range app.Behaviors {
		writeScenario(b, s)
	}
	b.WriteString("\n")

	b.WriteString("=== Specification: stores ===\n")
	for _, store := range app.Stores {
		fmt.Fprintf(b, "%s: value type %s, initial %v, strategy %s\n", store.Name, store.ValueType, store.InitialValue, store.Strategy)
	}
	b.WriteString("\n")

	if len(app.Symbols.Bindings) > 0 {
		b.WriteString("=== Widget events and the store actions they run ===\n")
		b.WriteString("These are resolved from the spec. Wire exactly these.\n")
		for _, binding := range app.Symbols.Bindings {
			fmt.Fprintf(b, "%s -> %s.%s\n", binding.FullPath(), binding.Store, binding.Action)
		}
		b.WriteString("\n")
	}

	b.WriteString("=== Generated code you must read but never change ===\n")
	for _, path := range im.readOnlyFiles() {
		if err := appendFile(b, im.ProjectDir, path); err != nil {
			return err
		}
	}
	b.WriteString("\n")

	b.WriteString("=== The tests, all of them ===\n")
	b.WriteString("These are the definition of done. Every one of them must pass.\n\n")
	for _, task := range im.Tasks {
		if task.Type != planner.TaskTest {
			continue
		}
		if err := appendFile(b, im.ProjectDir, task.TargetFile); err != nil {
			return err
		}
	}
	b.WriteString("\n")

	return nil
}

// writeEditable writes the current contents of every file the model owns.
func (im *Implementer) writeEditable(b *strings.Builder, files []editableFile) error {
	b.WriteString("=== The files you are writing, as they stand now ===\n")
	for _, f := range files {
		fmt.Fprintf(b, "\n// role: %s", f.Role)
		if f.Class != "" {
			fmt.Fprintf(b, ", must declare class %s", f.Class)
		}
		b.WriteString("\n")
		if err := appendFile(b, im.ProjectDir, f.Path); err != nil {
			return err
		}
	}
	b.WriteString("\n")
	return nil
}

func writeOutputFormat(b *strings.Builder, files []editableFile) {
	b.WriteString("=== Output format ===\n")
	b.WriteString("Return one ```dart fence per file. The first line inside each fence must be a FILE header:\n\n")
	b.WriteString("```dart\n// FILE: lib/stores/example_cubit.dart\n<the whole file>\n```\n\n")
	b.WriteString("Return whole files, never fragments or diffs. You may write only these paths:\n")
	for _, f := range files {
		fmt.Fprintf(b, "  %s\n", f.Path)
	}
	b.WriteString("Any other path is discarded. Write no prose outside the fences.\n")
}

// readOnlyFiles is the generated code the model needs in order to write against
// it: state classes, the dumb widgets and pages, and the app entry point.
func (im *Implementer) readOnlyFiles() []string {
	var out []string

	for _, store := range im.App.Stores {
		base := shared.SnakeCase(shared.StoreBaseName(store.Name))
		out = append(out, fmt.Sprintf("lib/stores/%s_state.dart", base))
	}

	for _, comp := range im.App.UI {
		dir := "lib/widgets"
		if shared.IsPageName(comp.Name) {
			dir = "lib/pages"
		}
		out = append(out, fmt.Sprintf("%s/%s.dart", dir, shared.SnakeCase(comp.Name)))
	}

	out = append(out, "lib/app.dart")

	sort.Strings(out)
	return out
}

func writeScenario(b *strings.Builder, s ir.BehaviorScenario) {
	fmt.Fprintf(b, "Scenario: %s\n", s.ID)
	if len(s.GroupPath) > 0 {
		fmt.Fprintf(b, "  Group: %s\n", strings.Join(s.GroupPath, " > "))
	}
	if s.Description != "" && s.Description != s.ID {
		fmt.Fprintf(b, "  Description: %s\n", s.Description)
	}
	if s.Given != nil {
		fmt.Fprintf(b, "  Given: %s %s %s\n", s.Given.Target, s.Given.Op, s.Given.Value)
	}
	if s.When != "" {
		fmt.Fprintf(b, "  When: %s\n", s.When)
	}
	if s.Then != nil {
		fmt.Fprintf(b, "  Then: %s %s %s\n", s.Then.Target, s.Then.Op, s.Then.Value)
	}
	b.WriteString("\n")
}

// appendFile writes a file into the prompt under its own path. A file that is
// not there yet is announced rather than skipped, so the model is told the
// difference between "empty" and "absent".
func appendFile(b *strings.Builder, projectDir, rel string) error {
	full := filepath.Join(projectDir, rel)
	code, err := os.ReadFile(full)
	if os.IsNotExist(err) {
		fmt.Fprintf(b, "// %s (does not exist yet)\n\n", rel)
		return nil
	}
	if err != nil {
		return fmt.Errorf("read %s: %w", rel, err)
	}
	fmt.Fprintf(b, "// %s\n%s\n", rel, strings.TrimRight(string(code), "\n"))
	return nil
}
