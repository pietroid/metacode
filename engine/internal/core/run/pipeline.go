package run

import (
	"strings"

	"github.com/pietroid/metacode/engine/internal/behavior/rules"
	"github.com/pietroid/metacode/engine/internal/core/build"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/log"
	"github.com/pietroid/metacode/engine/internal/specs/data/rules"
	"github.com/pietroid/metacode/engine/internal/specs/model/rules"
	"github.com/pietroid/metacode/engine/internal/specs/project/rules"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
	"github.com/pietroid/metacode/engine/internal/specs/ui/rules"
)

// Scaffold runs every stage that needs no model: it reads the specs at paths,
// builds the app, plans the work, and writes the generated project into outDir.
//
// The body is the pipeline, one line per stage, in order. Each stage's own work
// and logging lives in its own function below, because this list is the first
// thing a reader of this engine should be able to take in.
//
// It is a function rather than a block inside runCommand so the golden test can
// drive the same code the CLI drives. A test that reimplemented the stage order
// would stop guarding it the first time the order changed.
func Scaffold(target Target, reporter *log.Reporter, logger log.Logger, paths spec.Paths, outDir string) (model.App, plan.Work, error) {
	var app model.App
	var work plan.Work

	raw, err := stage(reporter, "Parsing specs", func() (spec.RawSpecs, error) {
		return parseSpecs(logger, paths)
	})
	if err != nil {
		return app, work, err
	}

	app, err = stage(reporter, "Building the model", func() (model.App, error) {
		return buildModel(logger, raw)
	})
	if err != nil {
		return app, work, err
	}

	if _, err := stage(reporter, "Resolving symbols", func() (struct{}, error) {
		return struct{}{}, resolveSymbols(logger, &app)
	}); err != nil {
		return app, work, err
	}

	if _, err := stage(reporter, log.Stage("Scaffolding the "+target.Name+" project"), func() (struct{}, error) {
		return struct{}{}, target.Scaffold(&app, outDir)
	}); err != nil {
		return app, work, err
	}

	work, err = stage(reporter, "Planning", func() (plan.Work, error) {
		return planWork(logger, &app)
	})
	if err != nil {
		return app, work, err
	}

	if _, err := stage(reporter, "Scaffolding wrappers", func() (struct{}, error) {
		return struct{}{}, target.Wrappers(&app, work, outDir)
	}); err != nil {
		return app, work, err
	}

	// Tests come before the implement stage on purpose: they are derived from
	// the specs, they are the definition of done, and the one request that
	// implements the app is shown all of them.
	if _, err := stage(reporter, "Generating tests", func() (struct{}, error) {
		return struct{}{}, target.Tests(&app, work, outDir)
	}); err != nil {
		return app, work, err
	}

	if _, err := stage(reporter, "Removing stale output", func() (struct{}, error) {
		return struct{}{}, pruneStaleOutput(logger, target, &app, work, outDir)
	}); err != nil {
		return app, work, err
	}

	return app, work, nil
}

func parseSpecs(logger log.Logger, paths spec.Paths) (spec.RawSpecs, error) {
	raw, err := spec.Parse(paths)
	if err != nil {
		return raw, err
	}
	logger.Infof("parsed specs: %d project key(s), %d data key(s), %d ui key(s), %d behavior group(s)",
		len(raw.Project), len(raw.Data), len(raw.UI), len(raw.Behaviors))
	return raw, nil
}

func buildModel(logger log.Logger, raw spec.RawSpecs) (model.App, error) {
	app, err := build.App(raw)
	if err != nil {
		return app, err
	}
	for _, warning := range app.Warnings {
		logger.Warnf("%s", warning)
	}
	logger.Infof("built the model for %q: %d store(s), %d widget(s), %d scenario(s)",
		app.Project.Name, len(app.Stores), len(app.UI), len(app.Behaviors))
	for _, scenario := range app.Behaviors {
		logger.Debugf("scenario %s", scenario.ID)
	}
	return app, nil
}

// resolveSymbols cross-references the specs and reports what each spec kind's
// own rules say about it. A rule that cannot be worked around is an error; the
// rest are warnings, because a spec is usually still generable around them.
func resolveSymbols(logger log.Logger, app *model.App) error {
	if err := build.Resolve(app, catalog.Default()); err != nil {
		return err
	}
	if err := datarules.CheckSupported(app.Stores); err != nil {
		return err
	}

	for _, rule := range []struct {
		kind string
		errs []error
	}{
		{"project", projectrules.Validate(app.Project)},
		{"data", datarules.Validate(app.Stores)},
		{"ui", uirules.Validate(app.UI, catalog.Default())},
		{"models", modelrules.Validate(app.Models, app.Enums)},
		{"behaviors", behaviorrules.ValidateGivens(app)},
	} {
		for _, err := range rule.errs {
			logger.Warnf("%s rule: %s", rule.kind, err)
		}
	}

	logger.Infof("resolved %d store(s), %d widget(s), %d binding(s)",
		len(app.Symbols.Stores), len(app.Symbols.Widgets), len(app.Symbols.Bindings))
	for _, binding := range app.Symbols.Bindings {
		logger.Infof("binding: %s -> %s.%s (%d scenario(s))",
			binding.FullPath(), binding.Store, binding.Action, len(binding.ScenarioIDs))
	}
	return nil
}

func planWork(logger log.Logger, app *model.App) (plan.Work, error) {
	work, err := plan.Build(app)
	if err != nil {
		return work, err
	}
	logger.Infof("planned %d wrapper(s) and %d test(s)", len(work.Wrappers), len(work.Tests))
	logger.Debugf("wrappers: %s", strings.Join(work.Wrappers, ", "))
	return work, nil
}

func pruneStaleOutput(logger log.Logger, target Target, app *model.App, work plan.Work, outDir string) error {
	removed, err := target.Prune(app, work, outDir)
	for _, path := range removed {
		logger.Infof("removed stale %s", path)
	}
	return err
}
