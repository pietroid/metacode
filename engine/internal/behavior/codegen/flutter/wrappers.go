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

// Wrapper is one wrapper file to write: which widget it wraps, what class it
// declares, and where it goes. The last two come from the layout rules, so
// every stage that reads a wrapper file — the pruner, the implementer, the
// tests — computes the same answer.
type Wrapper struct {
	WidgetName string
	ClassName  string
	TargetFile string
}

// WrapperFiles turns the planned wrappers into the files that render them.
func WrapperFiles(work plan.Work) []Wrapper {
	out := make([]Wrapper, 0, len(work.Wrappers))
	for _, wrapper := range work.Wrappers {
		out = append(out, Wrapper{
			WidgetName: wrapper.Widget,
			ClassName:  dart.WrapperClass(wrapper.Widget),
			TargetFile: dart.WrapperFile(wrapper.Widget),
		})
	}
	return out
}

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

	wrappers := WrapperFiles(work)
	if len(wrappers) == 0 {
		return nil
	}

	if err := os.MkdirAll(filepath.Join(outDir, "lib", "wrappers"), 0755); err != nil {
		return fmt.Errorf("create wrappers dir: %w", err)
	}

	t := treeOf(app)
	generated := make(map[string]string) // target file -> wrapper class name
	for _, wrapper := range wrappers {
		code, err := wrapperBody(app, wrapper, t)
		if err != nil {
			return fmt.Errorf("wrapper %s: %w", wrapper.WidgetName, err)
		}

		path := filepath.Join(outDir, wrapper.TargetFile)
		if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
			return fmt.Errorf("create target dir: %w", err)
		}
		if err := os.WriteFile(path, []byte(withMarker(code)), 0644); err != nil {
			return fmt.Errorf("write wrapper %s: %w", path, err)
		}
		generated[wrapper.TargetFile] = wrapper.ClassName
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
func withMarker(code string) string {
	if strings.Contains(code, dart.Marker) {
		return code
	}
	return "// " + dart.Marker + " - DO NOT EDIT BY HAND\n" + code
}
