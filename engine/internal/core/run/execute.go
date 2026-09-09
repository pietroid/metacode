package run

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/llm"
	"github.com/pietroid/metacode/engine/internal/log"
)

// Execute parses CLI arguments and runs the requested command against target.
func Execute(target Target) error {
	if err := target.validate(); err != nil {
		return err
	}

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
		return runCommand(target, *verbose, *quiet)
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

func runCommand(target Target, verbose, quiet bool) error {
	logger := log.New(os.Stdout, logLevel(verbose, quiet))
	reporter := log.NewReporter(os.Stdout, logger)

	loadEnvFile(logger)

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

	app, work, err := Scaffold(target, reporter, logger, paths, paths.Root)
	if err != nil {
		return err
	}

	client := newLLMClient(logger, paths.Root)

	var impl Implementer
	if client != nil {
		impl = target.NewImplementer(client, logger, &app, work, paths.Root)
		if _, err := stage(reporter, "Implementing behavior", func() (struct{}, error) {
			return struct{}{}, impl.Implement(context.Background())
		}); err != nil {
			return err
		}
	}

	// A nil implementer leaves nothing to repair with, so the suite runs once
	// and reports what it finds.
	var repairer Repairer
	if impl != nil {
		repairer = impl
	}
	tests := NewTestRunner(paths.Root, target.TestCommand, logger)

	if _, err := stage(reporter, "Running tests", func() (struct{}, error) {
		return struct{}{}, Verify(context.Background(), tests, repairer, logger)
	}); err != nil {
		return err
	}
	logger.Infof("tests passed (%s)", Strategy(repairer))

	return nil
}

// logLevel maps the two verbosity flags onto a level. Both set is verbose: a
// run the user asked to see is more useful than one they asked to be quiet.
func logLevel(verbose, quiet bool) log.Level {
	switch {
	case verbose:
		return log.DebugLevel
	case quiet:
		return log.WarnLevel
	default:
		return log.InfoLevel
	}
}

// loadEnvFile picks up credentials from a .env file so the API key does not
// have to live in the shell environment. Real environment variables still win.
func loadEnvFile(logger log.Logger) {
	cwd, err := os.Getwd()
	if err != nil {
		logger.Warnf("could not read the working directory: %s", err)
		return
	}
	envPath, err := spec.Load(cwd)
	if err != nil {
		logger.Warnf("could not read %s: %s", spec.FileName, err)
		return
	}
	if envPath != "" {
		logger.Debugf("loaded environment from %s", envPath)
	}
}

// newLLMClient builds the traced client, or returns nil when no LLM is
// configured. Every call it makes is logged and written to a transcript under
// the project root.
func newLLMClient(logger log.Logger, projectDir string) llm.Client {
	cfg, err := llm.ConfigFromEnv()
	if err != nil {
		logger.Warnf("LLM not configured: %s", err)
		logger.Warnf("set ANTHROPIC_API_KEY in a .env file (see .spec.example) to enable generation, or METACODE_LLM_PROVIDER=openai with METACODE_LLM_BASE_URL and METACODE_LLM_API_KEY")
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
func stage[T any](reporter *log.Reporter, name log.Stage, fn func() (T, error)) (T, error) {
	reporter.Start(name)
	out, err := fn()
	reporter.End(name, err)
	return out, err
}
