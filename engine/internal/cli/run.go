package cli

import (
	"context"
	"flag"
	"fmt"
	"os"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/core/log"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	generatorsflutter "github.com/pietroid/metacode/engine/internal/generators/flutter"
	"github.com/pietroid/metacode/engine/internal/llm"
	"github.com/pietroid/metacode/engine/internal/modules/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/modules/data"
	"github.com/pietroid/metacode/engine/internal/modules/project"
	"github.com/pietroid/metacode/engine/internal/modules/ui"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
	"github.com/pietroid/metacode/engine/internal/planner"
	"github.com/pietroid/metacode/engine/internal/runner"
)

// Execute parses CLI arguments and runs the requested command.
func Execute() error {
	fs := flag.NewFlagSet("metacode", flag.ContinueOnError)
	verbose := fs.Bool("v", false, "enable verbose (debug) output")

	if err := fs.Parse(os.Args[1:]); err != nil {
		return err
	}

	args := fs.Args()
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "Usage: metacode <command> [options]")
		fmt.Fprintln(os.Stderr, "Commands:")
		fmt.Fprintln(os.Stderr, "  run   run the Metacode generator")
		return fmt.Errorf("no command provided")
	}

	switch args[0] {
	case "run":
		return runCommand(*verbose, args[1:])
	case "help", "--help", "-h":
		fmt.Println("Usage: metacode <command> [options]")
		fmt.Println("Commands:")
		fmt.Println("  run   run the Metacode generator")
		return nil
	default:
		return fmt.Errorf("unknown command: %s", args[0])
	}
}

func runCommand(verbose bool, args []string) error {
	minLevel := log.InfoLevel
	if verbose {
		minLevel = log.DebugLevel
	}
	logger := log.New(os.Stdout, minLevel)
	reporter := log.NewReporter(os.Stdout, logger)

	reporter.Start("Metacode run")
	defer func() { reporter.End("Metacode run", nil) }()

	logger.Debugf("verbose mode enabled")

	reporter.Start("Discovering specs")
	paths, err := spec.Discover("")
	if err != nil {
		reporter.End("Discovering specs", err)
		return err
	}
	logger.Debugf("discovered metacode root: %s", paths.Root)
	logger.Infof("specs found at %s", paths.Metacode)
	reporter.End("Discovering specs", nil)

	reporter.Start("Parsing specs")
	raw, err := spec.Parse(paths)
	if err != nil {
		reporter.End("Parsing specs", err)
		return err
	}
	logger.Debugf("project keys: %d", len(raw.Project))
	logger.Debugf("data keys: %d", len(raw.Data))
	logger.Debugf("ui keys: %d", len(raw.UI))
	logger.Debugf("behavior keys: %d", len(raw.Behaviors))
	logger.Infof("parsed 4 spec files")
	reporter.End("Parsing specs", nil)

	reporter.Start("Building IR")
	app, err := ir.Build(raw)
	if err != nil {
		reporter.End("Building IR", err)
		return err
	}
	logger.Debugf("stores: %d", len(app.Stores))
	logger.Debugf("widgets: %d", len(app.UI))
	logger.Debugf("scenarios: %d", len(app.Behaviors))
	logger.Debugf("symbols: %d", len(app.Symbols.Symbols))
	for _, w := range app.Warnings {
		logger.Warnf("%s", w)
	}
	logger.Infof("built IR for project %q", app.Project.Name)
	reporter.End("Building IR", nil)

	reporter.Start("Resolving symbols")
	cat := catalog.New()
	if err := app.Resolve(cat); err != nil {
		reporter.End("Resolving symbols", err)
		return err
	}
	for _, err := range project.Validate(app.Project) {
		logger.Warnf("project rule: %s", err)
	}
	for _, err := range data.Validate(app.Stores) {
		logger.Warnf("data rule: %s", err)
	}
	for _, err := range ui.Validate(app.UI, cat) {
		logger.Warnf("ui rule: %s", err)
	}
	logger.Debugf("resolved stores: %d", len(app.Symbols.Stores))
	logger.Debugf("resolved widgets: %d", len(app.Symbols.Widgets))
	logger.Debugf("resolved actions: %d", len(app.Symbols.Actions))
	logger.Debugf("resolved events: %d", len(app.Symbols.Events))
	logger.Debugf("resolved variables: %d", len(app.Symbols.Variables))
	logger.Infof("resolved symbols")
	reporter.End("Resolving symbols", nil)

	reporter.Start("Generating Flutter project")
	if err := flutter.GenerateAll(&app, paths.Root); err != nil {
		reporter.End("Generating Flutter project", err)
		return err
	}
	logger.Infof("generated flutter project")
	reporter.End("Generating Flutter project", nil)

	reporter.Start("Planning wrappers")
	tasks, err := planner.Plan(&app)
	if err != nil {
		reporter.End("Planning wrappers", err)
		return err
	}
	logger.Debugf("planned tasks: %d", len(tasks))
	reporter.End("Planning wrappers", nil)

	reporter.Start("Generating AI wrappers")
	llmCfg, err := llm.ConfigFromEnv()
	if err != nil {
		logger.Warnf("skipping AI wrapper generation: %s", err)
		logger.Warnf("set METACODE_LLM_BASE_URL and METACODE_LLM_API_KEY to enable wrappers")
		reporter.End("Generating AI wrappers", nil)
	} else {
		client := llm.NewClient(llmCfg, logger)
		if err := generatorsflutter.GenerateWrappers(context.Background(), &app, tasks, client, paths.Root); err != nil {
			reporter.End("Generating AI wrappers", err)
			return err
		}
		logger.Infof("generated AI wrappers")
		reporter.End("Generating AI wrappers", nil)
	}

	reporter.Start("Generating tests")
	if err := generatorsflutter.GenerateTests(&app, tasks, paths.Root); err != nil {
		reporter.End("Generating tests", err)
		return err
	}
	logger.Infof("generated tests")
	reporter.End("Generating tests", nil)

	testRunner := runner.NewTestRunner(paths.Root, &loggerReporter{logger: logger})

	if err == nil {
		reporter.Start("Running tests with fix loop")
		fixLoop := &runner.FixLoop{
			MaxIterations: 3,
			Runner:        testRunner,
			Client:        llm.NewClient(llmCfg, logger),
			ProjectDir:    paths.Root,
			Reporter:      &loggerReporter{logger: logger},
		}
		if err := fixLoop.Run(context.Background(), tasks); err != nil {
			reporter.End("Running tests with fix loop", err)
			return err
		}
		logger.Infof("tests passed")
		reporter.End("Running tests with fix loop", nil)
	} else {
		reporter.Start("Running tests")
		result, err := testRunner.Run(context.Background())
		if err != nil {
			reporter.End("Running tests", err)
			return err
		}
		if !result.Success {
			err := fmt.Errorf("tests failed: %d failure(s)", len(result.Failures))
			reporter.End("Running tests", err)
			return err
		}
		logger.Infof("tests passed")
		reporter.End("Running tests", nil)
	}

	_ = args
	return nil
}

type loggerReporter struct {
	logger log.Logger
}

func (l loggerReporter) Logf(format string, args ...any) {
	l.logger.Infof(format, args...)
}
