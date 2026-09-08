package flutter

import (
	"fmt"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/llm"
	dataflutter "github.com/pietroid/metacode/engine/internal/modules/data/codegen/flutter"
	projectflutter "github.com/pietroid/metacode/engine/internal/modules/project/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/modules/tests"
	testsflutter "github.com/pietroid/metacode/engine/internal/modules/tests/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
	uiflutter "github.com/pietroid/metacode/engine/internal/modules/ui/codegen/flutter"
	wrappersflutter "github.com/pietroid/metacode/engine/internal/modules/wrappers/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/planner"
)

// WrapperGenerator produces the wrapper layer that wires widgets to Cubits.
type WrapperGenerator = wrappersflutter.Generator

// GenerateAll runs the full Flutter generation pipeline for the given IR.
// It scaffolds the project, generates stores, and generates widgets.
func GenerateAll(app *ir.IR, outDir string) error {
	if err := projectflutter.Generate(app, outDir); err != nil {
		return fmt.Errorf("project generation: %w", err)
	}
	if err := dataflutter.Generate(app, outDir); err != nil {
		return fmt.Errorf("store generation: %w", err)
	}
	if err := uiflutter.Generate(app, catalog.New(), outDir); err != nil {
		return fmt.Errorf("widget generation: %w", err)
	}
	return nil
}

// NewWrapperGenerator selects the wrapper strategy. A nil client means no LLM
// is configured, so wrappers are rendered from the IR alone. This is the only
// place the choice is made.
func NewWrapperGenerator(client llm.Client) WrapperGenerator {
	if client == nil {
		return wrappersflutter.NewDeterministicGenerator()
	}
	return wrappersflutter.NewLLMGenerator(client)
}

// GenerateTests emits Cubit and widget tests for every test task in tasks.
func GenerateTests(app *ir.IR, tasks []planner.Task, outDir string) error {
	cases, err := tests.BuildTestCases(app, tasks)
	if err != nil {
		return fmt.Errorf("build test cases: %w", err)
	}
	if err := testsflutter.Generate(cases, outDir); err != nil {
		return fmt.Errorf("generate tests: %w", err)
	}
	return nil
}
