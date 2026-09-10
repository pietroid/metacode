package run

import (
	"context"
	"fmt"
	"sort"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
	"github.com/pietroid/metacode/engine/internal/llm"
	"github.com/pietroid/metacode/engine/internal/log"
)

// Target is one language the engine can generate. It is assembled once, in
// cmd/metacode, and the pipeline calls it without naming Flutter anywhere.
//
// A struct of functions rather than an interface. There is one target and one
// assembly point, so an interface would buy a second name for every stage and
// nothing else.
//
// Implementing behavior and running the suite are deliberately not here. The
// implement stage reaches a model through llm.Client and the fix loop reaches
// it back through Repairer, so those seams already exist; the test
// command is the only other thing that is language-specific, and it is a value.
type Target struct {
	// Name identifies the target in the run log.
	Name string

	// Scaffold writes everything derivable from the specs alone: the project,
	// the stores, the dumb widgets.
	Scaffold func(app *model.App, outDir string) error

	// Wrappers writes the layer that wires widgets to stores.
	Wrappers func(app *model.App, work plan.Work, outDir string) error

	// Tests writes one test per planned scenario.
	Tests func(app *model.App, work plan.Work, outDir string) error

	// Prune deletes generated files whose spec source is gone, returning the
	// paths it removed.
	Prune func(app *model.App, work plan.Work, outDir string) ([]string, error)

	// NewImplementer builds the stage that fills in behavior with a model's
	// help, and repairs it when the tests fail.
	NewImplementer func(client llm.Client, logger log.Logger, app *model.App, work plan.Work, outDir string) Implementer

	// TestCommand runs the generated suite, as command and arguments.
	TestCommand []string
}

// Implementer fills in the behavior a spec describes but cannot derive, and
// fixes it when the generated tests fail. One request writes the whole app, and
// one request carries every failure of a run.
type Implementer interface {
	// Implement writes the behavior of the whole app.
	Implement(ctx context.Context) error
	// Repair rewrites it so a set of failing tests passes.
	Repair(ctx context.Context, iteration int, failures []Failure) error
}

// validate reports a target that is missing a stage, so an incomplete assembly
// fails by name at the start of a run rather than as a nil call in the middle
// of one.
func (t Target) validate() error {
	missing := []string{}
	for name, set := range map[string]bool{
		"Scaffold":       t.Scaffold != nil,
		"Wrappers":       t.Wrappers != nil,
		"Tests":          t.Tests != nil,
		"Prune":          t.Prune != nil,
		"NewImplementer": t.NewImplementer != nil,
		"TestCommand":    len(t.TestCommand) > 0,
	} {
		if !set {
			missing = append(missing, name)
		}
	}
	if len(missing) == 0 {
		return nil
	}
	sort.Strings(missing)
	return fmt.Errorf("target %q is incomplete: %s not set", t.Name, strings.Join(missing, ", "))
}
