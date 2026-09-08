// Package flutter generates the wrapper widgets that connect the generated
// dumb widgets to the generated Cubits.
//
// Generation here is deterministic and renders from the IR alone: which
// wrappers exist, what they are called, where they are written, and how
// lib/app.dart is rewritten. The result compiles and is the baseline an LLM
// then refines, in one request covering the whole app, in the implementer
// stage. Asking a model for each wrapper body separately, as this package used
// to, spent a request per widget on a file the next stage would look at again
// anyway.
package flutter

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/core/order"
	"github.com/pietroid/metacode/engine/internal/modules/codegen"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
	"github.com/pietroid/metacode/engine/internal/planner"
)

// Generator produces the wrapper layer for an application.
type Generator interface {
	// Name identifies the strategy, so callers can report which one ran
	// without having to know how the choice was made.
	Name() string
	Generate(ctx context.Context, app *ir.IR, tasks []planner.Task, outDir string) error
}

// Plan describes one wrapper to generate: which widget it wraps, what the
// wrapper class is called, and which file it is written to. The file comes from
// the planner so the fix loop, which reads wrapper files by task target, always
// finds them.
type Plan struct {
	WidgetName string
	ClassName  string
	TargetFile string
	Tasks      []planner.Task
}

// bodyFunc renders the Dart source of a single wrapper. plans is the full set,
// so a wrapper can reference the wrappers of its children.
type bodyFunc func(ctx context.Context, app *ir.IR, plan Plan, plans []Plan, outDir string) (string, error)

// PlanWrappers groups the wrapper tasks by the widget they wrap, in a stable
// order. Tasks that do not resolve to a widget are dropped.
func PlanWrappers(app *ir.IR, tasks []planner.Task) []Plan {
	byWidget := make(map[string][]planner.Task)
	for _, task := range tasks {
		if task.Type != planner.TaskWrapper {
			continue
		}
		widgetName := widgetNameForWrapperTask(task, app)
		if widgetName == "" {
			continue
		}
		byWidget[widgetName] = append(byWidget[widgetName], task)
	}

	plans := make([]Plan, 0, len(byWidget))
	for _, widgetName := range order.Keys(byWidget) {
		widgetTasks := byWidget[widgetName]
		plans = append(plans, Plan{
			WidgetName: widgetName,
			ClassName:  wrapperClassName(widgetName),
			TargetFile: widgetTasks[0].TargetFile,
			Tasks:      widgetTasks,
		})
	}
	return plans
}

// generate is the shared driver: it plans the wrappers, writes whatever body
// renders them, and rewrites lib/app.dart to use them.
func generate(ctx context.Context, app *ir.IR, tasks []planner.Task, outDir string, body bodyFunc) error {
	// Wrappers exist to wire widgets to Cubits. With no store there is nothing
	// to wire, and the dumb widgets already stand on their own.
	if len(app.Stores) == 0 {
		return nil
	}

	plans := PlanWrappers(app, tasks)
	if len(plans) == 0 {
		return nil
	}

	if err := os.MkdirAll(filepath.Join(outDir, "lib", "wrappers"), 0755); err != nil {
		return fmt.Errorf("create wrappers dir: %w", err)
	}

	generated := make(map[string]string) // target file -> wrapper class name
	for _, plan := range plans {
		code, err := body(ctx, app, plan, plans, outDir)
		if err != nil {
			return fmt.Errorf("wrapper %s: %w", plan.WidgetName, err)
		}

		code = withMarker(code)

		path := filepath.Join(outDir, plan.TargetFile)
		if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
			return fmt.Errorf("create target dir: %w", err)
		}
		if err := os.WriteFile(path, []byte(code), 0644); err != nil {
			return fmt.Errorf("write wrapper %s: %w", path, err)
		}
		generated[plan.TargetFile] = plan.ClassName
	}

	if err := updateAppDart(app, outDir, generated); err != nil {
		return fmt.Errorf("update app.dart: %w", err)
	}
	return nil
}

// childWrapperClasses maps every non-page widget name to its wrapper class, so
// a page wrapper can instantiate its children's wrappers instead of the dumb
// widgets.
func childWrapperClasses(plans []Plan) map[string]string {
	out := make(map[string]string, len(plans))
	for _, plan := range plans {
		if shared.IsPageName(plan.WidgetName) {
			continue
		}
		out[plan.WidgetName] = plan.ClassName
	}
	return out
}

// withMarker guarantees every wrapper file is identifiable as generated
// output. The deterministic strategy writes the header itself; a model writes
// whatever header it likes, and an unmarked file is one that stale-output
// pruning cannot safely delete.
func withMarker(code string) string {
	if strings.Contains(code, codegen.Marker) {
		return code
	}
	return "// " + codegen.Marker + " - DO NOT EDIT BY HAND\n" + code
}

func wrapperClassName(widgetName string) string {
	return shared.PascalCase(widgetName) + "Wrapper"
}

// findScenario returns the scenario with the given id.
func findScenario(app *ir.IR, id string) (ir.BehaviorScenario, error) {
	for _, s := range app.Behaviors {
		if s.ID == id {
			return s, nil
		}
	}
	return ir.BehaviorScenario{}, fmt.Errorf("scenario %q not found", id)
}

// splitWidgetRef splits "widget.member" when the root resolves to a widget.
func splitWidgetRef(app *ir.IR, ref string) (string, string, bool) {
	parts := strings.SplitN(ref, ".", 2)
	if len(parts) != 2 {
		return "", "", false
	}
	if sym, ok := app.Symbols.Lookup(parts[0]); !ok || sym.Kind != "widget" {
		return "", "", false
	}
	return parts[0], parts[1], true
}
