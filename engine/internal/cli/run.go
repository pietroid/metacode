package cli

import (
	"flag"
	"fmt"
	"os"

	"github.com/pietroid/metacode/engine/internal/ir"
	"github.com/pietroid/metacode/engine/internal/log"
	"github.com/pietroid/metacode/engine/internal/spec"
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

	_ = args
	return nil
}
