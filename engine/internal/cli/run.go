package cli

import (
	"context"
	"flag"
	"fmt"
	"os"

	"github.com/pietroid/metacode/engine/internal/core/env"
	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/core/log"
	"github.com/pietroid/metacode/engine/internal/core/spec"
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

	// Pick up credentials from a .env file so the API key does not have to live
	// in the shell environment. Real environment variables still win.
	cwd, err := os.Getwd()
	if err != nil {
		return err
	}
	if envPath, err := env.Load(cwd); err != nil {
		logger.Warnf("could not read %s: %s", env.FileName, err)
	} else if envPath != "" {
		logger.Debugf("loaded environment from %s", envPath)
	}

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

	// A nil client means no LLM is configured. Every strategy choice below is
	// made from this one value.
	var client llm.Client
	if llmCfg, err := llm.ConfigFromEnv(); err != nil {
		logger.Warnf("LLM not configured: %s", err)
		logger.Warnf("set ANTHROPIC_API_KEY in a .env file (see .env.example) to enable AI wrappers, or METACODE_LLM_PROVIDER=openai with METACODE_LLM_BASE_URL and METACODE_LLM_API_KEY")
	} else {
		client = llm.NewClient(llmCfg, logger)
	}

	wrapperGen := flutter.NewWrapperGenerator(client)

	reporter.Start("Generating wrappers")
	if err := wrapperGen.Generate(context.Background(), &app, tasks, paths.Root); err != nil {
		reporter.End("Generating wrappers", err)
		return err
	}
	logger.Infof("generated %s wrappers", wrapperGen.Name())
	reporter.End("Generating wrappers", nil)

	reporter.Start("Generating tests")
	if err := flutter.GenerateTests(&app, tasks, paths.Root); err != nil {
		reporter.End("Generating tests", err)
		return err
	}
	logger.Infof("generated tests")
	reporter.End("Generating tests", nil)

	verifier := runner.NewVerifier(
		runner.NewTestRunner(paths.Root, &loggerReporter{logger: logger}),
		client,
		paths.Root,
		&loggerReporter{logger: logger},
	)

	reporter.Start("Running tests")
	if err := verifier.Run(context.Background(), tasks); err != nil {
		reporter.End("Running tests", err)
		return err
	}
	logger.Infof("tests passed (%s)", verifier.Name())
	reporter.End("Running tests", nil)

	return nil
}

type loggerReporter struct {
	logger log.Logger
}

func (l loggerReporter) Logf(format string, args ...any) {
	l.logger.Infof(format, args...)
}
