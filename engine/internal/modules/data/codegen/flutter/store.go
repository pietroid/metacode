// Package flutter implements the Flutter code-generation step for the data module.
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
	"github.com/pietroid/metacode/engine/internal/modules/data"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
)

//go:embed templates/*.tmpl
var templates embed.FS

// Generate emits Cubit state classes and Cubit classes for every store.
func Generate(app *ir.IR, outDir string) error {
	storesDir := filepath.Join(outDir, "lib", "stores")
	if err := os.MkdirAll(storesDir, 0755); err != nil {
		return fmt.Errorf("create stores dir: %w", err)
	}

	tmpl, err := template.ParseFS(templates, "templates/*.tmpl")
	if err != nil {
		return fmt.Errorf("parse templates: %w", err)
	}

	for _, store := range app.Stores {
		base := shared.StoreBaseName(store.Name)
		dartType := data.DartTypeFor(store.ValueType)
		initialLiteral := data.DartLiteral(store.InitialValue, dartType)
		stateClass := shared.PascalCase(base) + "State"
		cubitClass := shared.PascalCase(base) + "Cubit"
		stateFile := shared.SnakeCase(base) + "_state.dart"
		cubitFile := shared.SnakeCase(base) + "_cubit.dart"
		methods := buildMethods(app, store)

		stateData := struct {
			StoreName  string
			StateClass string
			DartType   string
		}{
			StoreName:  store.Name,
			StateClass: stateClass,
			DartType:   dartType,
		}
		if err := codegen.ExecuteTemplate(tmpl, "state.dart.tmpl", filepath.Join(storesDir, stateFile), stateData); err != nil {
			return fmt.Errorf("state %s: %w", store.Name, err)
		}

		cubitData := struct {
			StoreName      string
			CubitClass     string
			StateClass     string
			StateFile      string
			InitialLiteral string
			Methods        string
		}{
			StoreName:      store.Name,
			CubitClass:     cubitClass,
			StateClass:     stateClass,
			StateFile:      stateFile,
			InitialLiteral: initialLiteral,
			Methods:        methods,
		}
		if err := codegen.ExecuteTemplate(tmpl, "cubit.dart.tmpl", filepath.Join(storesDir, cubitFile), cubitData); err != nil {
			return fmt.Errorf("cubit %s: %w", store.Name, err)
		}
	}
	return nil
}

// storeAction is one method the generated Cubit must expose, together with the
// scenarios that specify what it does.
type storeAction struct {
	Name      string
	Scenarios []ir.BehaviorScenario
}

// collectActions gathers the actions a store must expose. They come from two
// places, both of them the spec: a widget event bound to the store (resolved in
// the IR, see ir.Binding) and an explicit "when: storeName.action" reference.
//
// Nothing is inferred from the store's type. Adding a default "increment" to
// every numeric store, as this generator used to, put a method on the Cubit
// that no scenario asked for and hid the absence of the ones that were asked
// for.
func collectActions(app *ir.IR, store ir.Store) []storeAction {
	index := make(map[string]int)
	var actions []storeAction

	add := func(name, scenarioID string) {
		i, ok := index[name]
		if !ok {
			index[name] = len(actions)
			actions = append(actions, storeAction{Name: name})
			i = len(actions) - 1
		}
		if s, ok := findScenario(app, scenarioID); ok {
			actions[i].Scenarios = append(actions[i].Scenarios, s)
		}
	}

	for _, b := range app.Symbols.BindingsForStore(store.Name) {
		for _, id := range b.ScenarioIDs {
			add(b.Action, id)
		}
	}

	for _, b := range app.Behaviors {
		root, action := data.SplitDot(b.When)
		if root == store.Name && action != "" {
			add(action, b.ID)
		}
	}

	return actions
}

func findScenario(app *ir.IR, id string) (ir.BehaviorScenario, bool) {
	for _, s := range app.Behaviors {
		if s.ID == id {
			return s, true
		}
	}
	return ir.BehaviorScenario{}, false
}

// buildMethods emits one method per action the specs bind to this store.
//
// The bodies are deliberately absent. An action body is business logic, and in
// this engine business logic comes from the behavior scenarios through the fix
// loop, not from a lookup table in the generator. Hardcoding "increment" and
// "decrement" here made the counter app work and made every other app quietly
// wrong, and it pushed real rules into the wrapper layer, where a generated
// wrapper reached through cubit.emit because the Cubit had no method to call.
//
// Each method carries the scenarios that specify it, so the fix loop and a
// human reader see the same requirement in the same place.
func buildMethods(app *ir.IR, store ir.Store) string {
	var b strings.Builder
	for _, action := range collectActions(app, store) {
		if b.Len() > 0 {
			b.WriteString("\n")
		}
		for _, line := range specificationComment(action) {
			fmt.Fprintf(&b, "  %s\n", line)
		}
		fmt.Fprintf(&b, "  void %s() {\n", action.Name)
		fmt.Fprintf(&b, "    throw UnimplementedError('%s is not implemented yet');\n", action.Name)
		b.WriteString("  }\n")
	}
	return b.String()
}

// specificationComment renders the scenarios an action must satisfy as Dart doc
// comments.
func specificationComment(action storeAction) []string {
	if len(action.Scenarios) == 0 {
		return []string{fmt.Sprintf("/// No scenario specifies %s.", action.Name)}
	}
	lines := []string{"/// Specified by:"}
	for _, s := range action.Scenarios {
		lines = append(lines, fmt.Sprintf("///   %s: %s", s.ID, scenarioSummary(s)))
	}
	return lines
}

func scenarioSummary(s ir.BehaviorScenario) string {
	var parts []string
	if s.Given != nil {
		parts = append(parts, fmt.Sprintf("given %s %s %s", s.Given.Target, s.Given.Op, s.Given.Value))
	}
	if s.Then != nil {
		parts = append(parts, fmt.Sprintf("then %s %s %s", s.Then.Target, s.Then.Op, s.Then.Value))
	}
	return strings.Join(parts, ", ")
}
