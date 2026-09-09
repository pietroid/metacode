// Package flutter implements the Flutter code-generation step for the project module.
package projectflutter

import (
	"embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/project/rules"
)

//go:embed all:templates
var templates embed.FS

// Generate scaffolds the Flutter project root by walking the embedded template
// tree, mirroring its directory structure under outDir, and rendering every
// file with the project data. Adding static files to the template tree does
// not require changes to this generator.
func Generate(app *model.App, outDir string) error {
	fsys, err := fs.Sub(templates, "templates")
	if err != nil {
		return fmt.Errorf("open templates: %w", err)
	}

	tmpl := template.New("project")
	if err := fs.WalkDir(fsys, ".", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		b, err := fs.ReadFile(fsys, path)
		if err != nil {
			return fmt.Errorf("read template %s: %w", path, err)
		}
		if _, err := tmpl.New(path).Parse(string(b)); err != nil {
			return fmt.Errorf("parse template %s: %w", path, err)
		}
		return nil
	}); err != nil {
		return err
	}

	data := buildProjectData(app)
	return fs.WalkDir(fsys, ".", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		relPath := strings.TrimSuffix(path, ".tmpl")
		outPath := filepath.Join(outDir, filepath.FromSlash(relPath))
		if d.IsDir() {
			return os.MkdirAll(outPath, 0755)
		}
		return dart.ExecuteTemplate(tmpl, path, outPath, data)
	})
}

type projectData struct {
	PackageName string
	Description string
	PageName    string
	FileName    string
	Title       string
	ClassName   string
	ArgList     string
}

func buildProjectData(app *model.App) projectData {
	pageName := dart.FirstPageName(app.UI)
	return projectData{
		PackageName: projectrules.PackageName(app.Project.Name),
		Description: app.Project.Description,
		PageName:    pageName,
		FileName:    dart.SnakeCase(pageName) + ".dart",
		Title:       dart.DartStringLiteral(app.Project.Name),
		ClassName:   dart.WidgetClass(pageName),
		ArgList:     buildArgList(app.UI, pageName),
	}
}

func buildArgList(components []model.UIComponent, pageName string) string {
	page := dart.FindComponent(components, pageName)
	if page == nil {
		return ""
	}
	vars := model.UniqueVariables(page.Variables)
	if len(vars) == 0 {
		return ""
	}
	parts := make([]string, len(vars))
	for i, v := range vars {
		parts[i] = fmt.Sprintf("%s: %s", v.Name, dart.VariablePlaceholder(v.Type))
	}
	return "(" + strings.Join(parts, ", ") + ")"
}
