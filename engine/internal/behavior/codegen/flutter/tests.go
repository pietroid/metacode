package behaviorflutter

import (
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"text/template"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
)

//go:embed templates/*.tmpl
var templates embed.FS

// generateTestFiles writes one Dart test file per TestCase into outDir/test.
// One scenario produces one file.
func generateTestFiles(cases []TestCase, outDir string) error {
	testDir := filepath.Join(outDir, "test")
	if err := os.MkdirAll(testDir, 0755); err != nil {
		return fmt.Errorf("create test dir: %w", err)
	}

	tmpl, err := template.New("tests").Funcs(template.FuncMap{
		"dartQuote": dart.DartStringLiteral,
	}).ParseFS(templates, "templates/*.tmpl")
	if err != nil {
		return fmt.Errorf("parse templates: %w", err)
	}

	for _, tc := range cases {
		path := filepath.Join(outDir, tc.TargetFile)
		if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
			return fmt.Errorf("create test target dir: %w", err)
		}

		// One template, because there is one kind of test: a scenario is a
		// behavior of the whole app, so it is verified against the whole app.
		if err := dart.ExecuteTemplate(tmpl, "widget_test.dart.tmpl", path, tc); err != nil {
			return fmt.Errorf("test %s: %w", tc.ID, err)
		}
	}

	return nil
}

// GenerateTests writes one test per planned scenario: it derives the test cases
// from the model and renders them.
func GenerateTests(app *model.App, work plan.Work, outDir string) error {
	cases, err := BuildTestCases(app, work)
	if err != nil {
		return fmt.Errorf("build test cases: %w", err)
	}
	if err := generateTestFiles(cases, outDir); err != nil {
		return fmt.Errorf("generate tests: %w", err)
	}
	return nil
}
