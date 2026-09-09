package dart

import (
	"fmt"
	"os"
	"text/template"
)

// ExecuteTemplate renders the named template from tmpl to path using data.
func ExecuteTemplate(tmpl *template.Template, name, path string, data any) error {
	f, err := os.Create(path)
	if err != nil {
		return fmt.Errorf("create %s: %w", path, err)
	}
	defer f.Close()
	if err := tmpl.ExecuteTemplate(f, name, data); err != nil {
		return fmt.Errorf("execute %s: %w", name, err)
	}
	return nil
}
