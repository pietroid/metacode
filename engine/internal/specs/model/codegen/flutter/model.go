// Package modelflutter writes the Dart classes for the shapes models.yaml
// declares. A store holding `list(task)` gets a real `List<Task>`, which is the
// difference between a state a compiler checks and one holding `dynamic`.
package modelflutter

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

// Generate writes one file per declared model and enum into lib/models.
func Generate(app *model.App, outDir string) error {
	if len(app.Models) == 0 && len(app.Enums) == 0 {
		return nil
	}

	dir := filepath.Join(outDir, "lib", "models")
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("create models dir: %w", err)
	}

	tmpl, err := template.ParseFS(templates, "templates/*.tmpl")
	if err != nil {
		return fmt.Errorf("parse templates: %w", err)
	}

	for _, m := range app.Models {
		if err := writeModel(m, tmpl, dir); err != nil {
			return fmt.Errorf("model %s: %w", m.Name, err)
		}
	}
	for _, e := range app.Enums {
		if err := writeEnum(e, tmpl, dir); err != nil {
			return fmt.Errorf("enum %s: %w", e.Name, err)
		}
	}
	return nil
}

type modelData struct {
	SpecName   string
	ClassName  string
	Imports    string
	Params     string
	Fields     string
	CopyParams string
	CopyArgs   string
	Props      string
}

func writeModel(m model.Model, tmpl *template.Template, dir string) error {
	var params, fields, copyParams, copyArgs, props []string
	for _, f := range m.Fields {
		dartType := dart.DartTypeFor(f.Type)
		if f.Optional {
			dartType += "?"
		}
		required := "required "
		if f.Optional {
			required = ""
		}
		params = append(params, fmt.Sprintf("%sthis.%s", required, f.Name))
		fields = append(fields, fmt.Sprintf("  final %s %s;", dartType, f.Name))
		copyParams = append(copyParams, fmt.Sprintf("%s? %s", strings.TrimSuffix(dartType, "?"), f.Name))
		copyArgs = append(copyArgs, fmt.Sprintf("      %s: %s ?? this.%s,", f.Name, f.Name, f.Name))
		props = append(props, f.Name)
	}

	data := modelData{
		SpecName:   m.Name,
		ClassName:  dart.PascalCase(m.Name),
		Imports:    modelImports(m),
		Params:     strings.Join(params, ", "),
		Fields:     strings.Join(fields, "\n"),
		CopyParams: strings.Join(copyParams, ", "),
		CopyArgs:   strings.Join(copyArgs, "\n"),
		Props:      strings.Join(props, ", "),
	}
	path := filepath.Join(dir, dart.SnakeCase(m.Name)+".dart")
	return dart.ExecuteTemplate(tmpl, "model.dart.tmpl", path, data)
}

// modelImports names the sibling files a model's fields refer to. A field whose
// type is not a primitive is another declared shape, and it lives next door.
func modelImports(m model.Model) string {
	seen := make(map[string]bool)
	var out []string
	for _, f := range m.Fields {
		name := f.Type
		if inner, ok := model.ListElement(name); ok {
			name = inner
		}
		if !dart.IsClassName(dart.DartTypeFor(name)) || name == m.Name || seen[name] {
			continue
		}
		seen[name] = true
		out = append(out, fmt.Sprintf("import '%s.dart';", dart.SnakeCase(name)))
	}
	if len(out) == 0 {
		return ""
	}
	return strings.Join(out, "\n") + "\n"
}

type enumData struct {
	SpecName  string
	ClassName string
	Values    string
}

func writeEnum(e model.Enum, tmpl *template.Template, dir string) error {
	values := make([]string, len(e.Values))
	for i, v := range e.Values {
		values[i] = fmt.Sprintf("  %s,", dart.EnumValue(v))
	}
	data := enumData{
		SpecName:  e.Name,
		ClassName: dart.PascalCase(e.Name),
		Values:    strings.Join(values, "\n"),
	}
	path := filepath.Join(dir, dart.SnakeCase(e.Name)+".dart")
	return dart.ExecuteTemplate(tmpl, "enum.dart.tmpl", path, data)
}
