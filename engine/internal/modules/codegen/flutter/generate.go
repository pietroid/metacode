package flutter

import (
	"fmt"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	dataflutter "github.com/pietroid/metacode/engine/internal/modules/data/codegen/flutter"
	projectflutter "github.com/pietroid/metacode/engine/internal/modules/project/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
	uiflutter "github.com/pietroid/metacode/engine/internal/modules/ui/codegen/flutter"
)

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
