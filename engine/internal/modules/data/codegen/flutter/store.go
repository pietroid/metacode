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

	actions := collectActions(app)
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
		methods := buildMethods(actions[store.Name], stateClass, dartType)

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

// collectActions gathers action names referenced for each store. It scans
// explicit action references from behavior "when" expressions and also infers
// a default "increment" action for numeric value stores.
func collectActions(app *ir.IR) map[string]map[string]bool {
	actions := make(map[string]map[string]bool)
	for _, s := range app.Stores {
		actions[s.Name] = make(map[string]bool)
	}

	for _, b := range app.Behaviors {
		if b.When != "" {
			store, action := data.SplitDot(b.When)
			if store != "" && action != "" {
				if _, ok := actions[store]; ok {
					actions[store][action] = true
				}
			}
		}
	}

	for _, s := range app.Stores {
		if data.IsNumericType(s.ValueType) && s.ValueType != "" {
			actions[s.Name]["increment"] = true
		}
	}

	return actions
}

func buildMethods(actionSet map[string]bool, stateClass, dartType string) string {
	var b strings.Builder
	for action := range actionSet {
		switch action {
		case "increment":
			fmt.Fprintf(&b, "  void increment() => emit(state.copyWith(value: state.value + 1));\n")
		case "decrement":
			fmt.Fprintf(&b, "  void decrement() => emit(state.copyWith(value: state.value - 1));\n")
		default:
			fmt.Fprintf(&b, "  void %s() {\n    throw UnimplementedError('%s has not been implemented yet');\n  }\n", action, action)
		}
	}
	return b.String()
}
