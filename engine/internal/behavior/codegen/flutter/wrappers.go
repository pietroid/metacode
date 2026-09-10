package behaviorflutter

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
)

// GenerateWrappers writes one wrapper file per planned wrapper, then rewrites
// lib/app.dart to use them.
//
// Bodies are rendered from the model alone: the result compiles, and it is the
// baseline the implement stage refines in one request covering the whole app.
func GenerateWrappers(app *model.App, work plan.Work, outDir string) error {
	// Wrappers exist to wire widgets to Cubits. With no store there is nothing
	// to wire, and the dumb widgets already stand on their own.
	if len(app.Stores) == 0 {
		return nil
	}

	if len(work.Wrappers) == 0 {
		return nil
	}

	if err := os.MkdirAll(filepath.Join(outDir, "lib", "wrappers"), 0755); err != nil {
		return fmt.Errorf("create wrappers dir: %w", err)
	}

	t := treeOf(app)
	generated := make(map[string]string) // target file -> wrapper class name
	for _, widget := range work.Wrappers {
		code, err := wrapperBody(app, widget, t)
		if err != nil {
			return fmt.Errorf("wrapper %s: %w", widget, err)
		}

		target := dart.WrapperFile(widget)
		path := filepath.Join(outDir, target)
		if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
			return fmt.Errorf("create target dir: %w", err)
		}
		// A wrapper a model has wired is left alone. The baseline below is
		// only a starting point, and rewriting it every run threw away the
		// wiring before the implement stage had a chance to keep it.
		// app.dart still has to name the wrapper, so this skips the write and
		// not the registration.
		if !dart.IsImplemented(path) {
			if err := os.WriteFile(path, []byte(withMarker(code)), 0644); err != nil {
				return fmt.Errorf("write wrapper %s: %w", path, err)
			}
		}
		generated[target] = dart.WrapperClass(widget)
	}

	if err := updateAppDart(app, outDir, generated); err != nil {
		return fmt.Errorf("update app.dart: %w", err)
	}
	return nil
}

// withMarker guarantees every wrapper file is identifiable as generated
// output. Rendering writes the header itself; a model writes whatever header it
// likes, and an unmarked file is one that stale-output pruning cannot safely
// delete.
//
// The header this writes is the stub one, because everything this file
// renders is a baseline no model has seen. That is what tells the next run it
// may overwrite the file, and the implement stage that it still needs wiring.
func withMarker(code string) string {
	if strings.Contains(code, dart.Marker) {
		return code
	}
	return dart.StubHeader + "\n" + code
}
