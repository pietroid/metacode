// Package flutter implements the Flutter test code-generation step for the tests module.
package flutter

import (
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"text/template"

	"github.com/pietroid/metacode/engine/internal/modules/codegen"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
	"github.com/pietroid/metacode/engine/internal/modules/tests"
)

//go:embed templates/*.tmpl
var templates embed.FS

// Generate writes one Dart test file per TestCase into outDir/test.
func Generate(cases []tests.TestCase, outDir string) error {
	testDir := filepath.Join(outDir, "test")
	if err := os.MkdirAll(testDir, 0755); err != nil {
		return fmt.Errorf("create test dir: %w", err)
	}

	tmpl, err := template.New("tests").Funcs(template.FuncMap{
		"dartQuote": shared.DartStringLiteral,
	}).ParseFS(templates, "templates/*.tmpl")
	if err != nil {
		return fmt.Errorf("parse templates: %w", err)
	}

	for _, tc := range cases {
		path := filepath.Join(outDir, tc.TargetFile)
		if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
			return fmt.Errorf("create test target dir: %w", err)
		}

		var templateName string
		switch tc.Type {
		case tests.TestTypeCubit:
			templateName = "cubit_test.dart.tmpl"
		case tests.TestTypeWidget:
			templateName = "widget_test.dart.tmpl"
		default:
			return fmt.Errorf("unknown test type %q for %s", tc.Type, tc.ID)
		}

		if err := codegen.ExecuteTemplate(tmpl, templateName, path, tc); err != nil {
			return fmt.Errorf("test %s: %w", tc.ID, err)
		}
	}

	return nil
}
