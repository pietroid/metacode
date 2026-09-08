package cli

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/pietroid/metacode/engine/internal/core/env"
	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/core/log"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/implementer"
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
	verbose := fs.Bool("v", false, "log every LLM prompt and response in full")
	quiet := fs.Bool("q", false, "log stage results only")

	if err := fs.Parse(os.Args[1:]); err != nil {
		return err
	}

	args := fs.Args()
	if len(args) == 0 {
		usage(os.Stderr)
		return fmt.Errorf("no command provided")
	}

	switch args[0] {
	case "run":
		return runCommand(*verbose, *quiet)
	case "help", "--help", "-h":
		usage(os.Stdout)
		return nil
	default:
		return fmt.Errorf("unknown command: %s", args[0])
	}
}

func usage(w *os.File) {
	fmt.Fprintln(w, "Usage: metacode [-v|-q] <command>")
	fmt.Fprintln(w, "Commands:")
	fmt.Fprintln(w, "  run   run the Metacode generator")
	fmt.Fprintln(w, "Options:")
	fmt.Fprintln(w, "  -v    log every LLM prompt and response in full")
	fmt.Fprintln(w, "  -q    log stage results only")
	fmt.Fprintf(w, "\nEvery run writes one file per LLM call to %s.\n", llm.TraceDirName)
}

func runCommand(verbose, quiet bool) error {
	minLevel := log.InfoLevel
	switch {
	case verbose:
		minLevel = log.DebugLevel
	case quiet:
		minLevel = log.WarnLevel
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

	started := time.Now()
	reporter.Start("Metacode run")
	defer func() {
		logger.Infof("total time %s", time.Since(started).Round(time.Millisecond))
		reporter.End("Metacode run", nil)
	}()

	paths, err := stage(reporter, "Discovering specs", func() (spec.Paths, error) {
		p, err := spec.Discover("")
		if err == nil {
			logger.Debugf("metacode root: %s", p.Root)
			logger.Infof("specs found at %s", p.Metacode)
		}
		return p, err
	})
	if err != nil {
		return err
	}

	raw, err := stage(reporter, "Parsing specs", func() (spec.RawSpecs, error) {
		r, err := spec.Parse(paths)
		if err == nil {
			logger.Infof("parsed specs: %d project key(s), %d data key(s), %d ui key(s), %d behavior group(s)",
				len(r.Project), len(r.Data), len(r.UI), len(r.Behaviors))
		}
		return r, err
	})
	if err != nil {
		return err
	}

	app, err := stage(reporter, "Building IR", func() (ir.IR, error) {
		a, err := ir.Build(raw)
		if err != nil {
			return a, err
		}
		for _, w := range a.Warnings {
			logger.Warnf("%s", w)
		}
		logger.Infof("built IR for %q: %d store(s), %d widget(s), %d scenario(s)",
			a.Project.Name, len(a.Stores), len(a.UI), len(a.Behaviors))
		for _, s := range a.Behaviors {
			logger.Debugf("scenario %s", s.ID)
		}
		return a, nil
	})
	if err != nil {
		return err
	}

	cat := catalog.New()
	if _, err := stage(reporter, "Resolving symbols", func() (struct{}, error) {
		if err := app.Resolve(cat); err != nil {
			return struct{}{}, err
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
		logger.Infof("resolved %d store(s), %d widget(s), %d binding(s)",
			len(app.Symbols.Stores), len(app.Symbols.Widgets), len(app.Symbols.Bindings))
		for _, b := range app.Symbols.Bindings {
			logger.Infof("binding: %s -> %s.%s (%d scenario(s))", b.FullPath(), b.Store, b.Action, len(b.ScenarioIDs))
		}
		return struct{}{}, nil
	}); err != nil {
		return err
	}

	if _, err := stage(reporter, "Scaffolding Flutter project", func() (struct{}, error) {
		return struct{}{}, flutter.GenerateAll(&app, paths.Root)
	}); err != nil {
		return err
	}

	tasks, err := stage(reporter, "Planning", func() ([]planner.Task, error) {
		t, err := planner.Plan(&app)
		if err == nil {
			logger.Infof("planned %d task(s)", len(t))
			for _, task := range t {
				logger.Debugf("task %s -> %s", task.ID, task.TargetFile)
			}
		}
		return t, err
	})
	if err != nil {
		return err
	}

	wrapperGen := flutter.NewWrapperGenerator()
	if _, err := stage(reporter, "Scaffolding wrappers", func() (struct{}, error) {
		return struct{}{}, wrapperGen.Generate(context.Background(), &app, tasks, paths.Root)
	}); err != nil {
		return err
	}

	// Tests come before the implement stage on purpose: they are derived from
	// the specs, they are the definition of done, and the one request that
	// implements the app is shown all of them.
	if _, err := stage(reporter, "Generating tests", func() (struct{}, error) {
		return struct{}{}, flutter.GenerateTests(&app, tasks, paths.Root)
	}); err != nil {
		return err
	}

	if _, err := stage(reporter, "Removing stale output", func() (struct{}, error) {
		removed, err := flutter.PruneStaleOutput(&app, tasks, paths.Root)
		for _, path := range removed {
			logger.Infof("removed stale %s", path)
		}
		return struct{}{}, err
	}); err != nil {
		return err
	}

	client := newLLMClient(logger, paths.Root)

	var impl *implementer.Implementer
	if client != nil {
		impl = implementer.New(client, logger, &app, tasks, paths.Root)
		if _, err := stage(reporter, "Implementing behavior", func() (struct{}, error) {
			return struct{}{}, impl.Implement(context.Background())
		}); err != nil {
			return err
		}
	}

	// A nil implementer leaves the verifier with nothing to repair with, so it
	// runs the suite once and reports what it finds.
	var repairer runner.Repairer
	if impl != nil {
		repairer = impl
	}
	verifier := runner.NewVerifier(
		runner.NewTestRunner(paths.Root, &loggerReporter{logger: logger}),
		repairer,
		&loggerReporter{logger: logger},
	)

	if _, err := stage(reporter, "Running tests", func() (struct{}, error) {
		return struct{}{}, verifier.Run(context.Background())
	}); err != nil {
		return err
	}
	logger.Infof("tests passed (%s)", verifier.Name())

	return nil
}

// newLLMClient builds the traced client, or returns nil when no LLM is
// configured. Every call it makes is logged and written to a transcript under
// the project root.
func newLLMClient(logger log.Logger, projectDir string) llm.Client {
	cfg, err := llm.ConfigFromEnv()
	if err != nil {
		logger.Warnf("LLM not configured: %s", err)
		logger.Warnf("set ANTHROPIC_API_KEY in a .env file (see .env.example) to enable generation, or METACODE_LLM_PROVIDER=openai with METACODE_LLM_BASE_URL and METACODE_LLM_API_KEY")
		return nil
	}

	logger.Infof("llm: provider=%s model=%s max_tokens=%d", cfg.Provider, cfg.Model, cfg.MaxTokens)
	if err := llm.ResetTraceDir(projectDir); err != nil {
		logger.Warnf("could not clear the LLM trace directory: %s", err)
	}
	logger.Infof("llm transcripts: %s", llm.TraceDirName)

	return llm.NewTracer(llm.NewClient(cfg, logger), logger, projectDir)
}

// stage runs one pipeline step under the reporter, so a step cannot be started
// without its result being reported.
func stage[T any](reporter log.Reporter, name log.Stage, fn func() (T, error)) (T, error) {
	reporter.Start(name)
	out, err := fn()
	reporter.End(name, err)
	return out, err
}

type loggerReporter struct {
	logger log.Logger
}

func (l loggerReporter) Logf(format string, args ...any) {
	l.logger.Infof(format, args...)
}
