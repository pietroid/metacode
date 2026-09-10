// Package flutter implements the Flutter code-generation step for the data module.
package dataflutter

import (
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/pietroid/metacode/engine/internal/behavior/rules"
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
		// A Cubit whose bodies a model has written is not re-scaffolded: the
		// bodies are the run's expensive output and the stub would erase them.
		// The signatures the specs imply can drift out of such a file, which
		// the implement stage detects and repairs. See AGENTS.md, "Lock and
		// diff".
		cubitPath := filepath.Join(storesDir, cubitFile)
		if dart.IsImplemented(cubitPath) {
			continue
		}
		if err := dart.ExecuteTemplate(tmpl, "cubit.dart.tmpl", cubitPath, cubitData); err != nil {
			return fmt.Errorf("cubit %s: %w", store.Name, err)
		}
	}
	return nil
}

// storeAction is one action of a store as this generator writes it. The
// action set itself comes from behavior/rules, because which actions a store
// has is a behavior fact; what this adds is the Dart the signature is written
// in.
type storeAction struct{ behaviorrules.StoreAction }

// Params is the action's parameter list, in the target language.
func (a storeAction) Params() string {
	if a.Indexed {
		return "int index"
	}
	return ""
}

func collectActions(app *model.App, store model.Store) []storeAction {
	from := behaviorrules.StoreActions(app, store)
	actions := make([]storeAction, 0, len(from))
	for _, a := range from {
		actions = append(actions, storeAction{a})
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
