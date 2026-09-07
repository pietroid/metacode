package flutter

import (
	"fmt"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/tests"
	codegenflutter "github.com/pietroid/metacode/engine/internal/modules/tests/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/planner"
)

// GenerateTests emits Cubit and widget tests for every test task in tasks.
// It delegates to the tests module for IR construction and to the Flutter
// test codegen module for Dart rendering.
func GenerateTests(app *ir.IR, tasks []planner.Task, outDir string) error {
	cases, err := tests.BuildTestCases(app, tasks)
	if err != nil {
		return fmt.Errorf("build test cases: %w", err)
	}
	if err := codegenflutter.Generate(cases, outDir); err != nil {
		return fmt.Errorf("generate tests: %w", err)
	}
	return nil
}
