// Package flutter implements the Flutter code-generation step for the data module.
package dataflutter

import (
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
)

//go:embed templates/*.tmpl
var templates embed.FS

// Generate emits Cubit state classes and Cubit classes for every store.
func Generate(app *model.App, outDir string) error {
	storesDir := filepath.Join(outDir, "lib", "stores")
	if err := os.MkdirAll(storesDir, 0755); err != nil {
		return fmt.Errorf("create stores dir: %w", err)
	}

	tmpl, err := template.ParseFS(templates, "templates/*.tmpl")
	if err != nil {
		return fmt.Errorf("parse templates: %w", err)
	}

	for _, store := range app.Stores {
		base := dart.StoreBaseName(store.Name)
		dartType := dart.DartTypeFor(store.ValueType)
		initialLiteral := dart.DartLiteral(store.InitialValue, dartType)
		stateClass := dart.PascalCase(base) + "State"
		cubitClass := dart.PascalCase(base) + "Cubit"
		stateFile := dart.SnakeCase(base) + "_state.dart"
		cubitFile := dart.SnakeCase(base) + "_cubit.dart"
		methods := buildMethods(app, store)

		stateData := struct {
			StoreName  string
			StateClass string
			DartType   string
			Imports    string
		}{
			StoreName:  store.Name,
			StateClass: stateClass,
			DartType:   dartType,
			Imports:    modelImport(app, store),
		}
		if err := dart.ExecuteTemplate(tmpl, "state.dart.tmpl", filepath.Join(storesDir, stateFile), stateData); err != nil {
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
		if err := dart.ExecuteTemplate(tmpl, "cubit.dart.tmpl", filepath.Join(storesDir, cubitFile), cubitData); err != nil {
			return fmt.Errorf("cubit %s: %w", store.Name, err)
		}
	}
	return nil
}

// storeAction is one method the generated Cubit must expose, together with the
// scenarios that specify what it does.
type storeAction struct {
	Name string
	// Indexed actions are run by a widget that is rendered once per row, so
	// they take the row. The signature is the contract the implement stage
	// writes a body for, and a contract the model has to correct is not one.
	Indexed   bool
	Scenarios []model.BehaviorScenario
}

// Params is the action's parameter list, in the target language.
func (a storeAction) Params() string {
	if a.Indexed {
		return "int index"
	}
	return ""
}

// collectActions gathers the actions a store must expose. They come from two
// places, both of them the spec: a widget event bound to the store (resolved in
// behavior/rules, see model.Binding) and an explicit "when: storeName.action".
//
// Nothing is inferred from the store's type. See AGENTS.md, "A store action
// body is business logic, so no generator writes it".
func collectActions(app *model.App, store model.Store) []storeAction {
	index := make(map[string]int)
	var actions []storeAction

	add := func(name string, indexed bool, scenarioID string) {
		i, ok := index[name]
		if !ok {
			index[name] = len(actions)
			actions = append(actions, storeAction{Name: name})
			i = len(actions) - 1
		}
		actions[i].Indexed = actions[i].Indexed || indexed
		if s, ok := app.ScenarioByID(scenarioID); ok {
			actions[i].Scenarios = append(actions[i].Scenarios, s)
		}
	}

	for _, b := range app.Symbols.BindingsForStore(store.Name) {
		for _, id := range b.ScenarioIDs {
			add(b.Action, b.Indexed, id)
		}
	}

	for _, b := range app.Behaviors {
		root, action := model.SplitRef(b.When)
		if root == store.Name && action != "" {
			add(action, false, b.ID)
		}
	}

	return actions
}

// buildMethods emits one method per action the specs bind to this store.
//
// The bodies are deliberately absent: an action body is business logic, and it
// comes from the behavior scenarios through the implement stage. See
// AGENTS.md, "A store action body is business logic, so no generator
// writes it".
//
// Each method carries the scenarios that specify it, so the implement stage and
// a human reader see the same requirement in the same place.
func buildMethods(app *model.App, store model.Store) string {
	var b strings.Builder
	for _, action := range collectActions(app, store) {
		if b.Len() > 0 {
			b.WriteString("\n")
		}
		for _, line := range specificationComment(action) {
			fmt.Fprintf(&b, "  %s\n", line)
		}
		fmt.Fprintf(&b, "  void %s(%s) {\n", action.Name, action.Params())
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

func scenarioSummary(s model.BehaviorScenario) string {
	var parts []string
	if s.Given != nil {
		parts = append(parts, fmt.Sprintf("given %s: %s", s.Given.Target, s.Given.Value))
	}
	if s.Then != nil {
		parts = append(parts, fmt.Sprintf("then %s should be %s", s.Then.Target, s.Then.Value))
	}
	return strings.Join(parts, ", ")
}

// modelImport names the model file a state holds, if it holds one. A state
// declaring `List<Task>` has to be able to say what a Task is.
func modelImport(app *model.App, store model.Store) string {
	m, ok := app.ElementModel(store.ValueType)
	if !ok {
		return ""
	}
	return fmt.Sprintf("import '../models/%s.dart';\n", dart.SnakeCase(m.Name))
}
