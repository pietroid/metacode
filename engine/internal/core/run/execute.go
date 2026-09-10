package run

import (
	"context"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/pietroid/metacode/engine/internal/core/lock"
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
	regenerate := fs.Bool("regenerate", false, "ignore the lock and rewrite every store and wrapper")

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
		return runCommand(target, Options{Regenerate: *regenerate}, *verbose, *quiet)
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
	fmt.Fprintln(w, "  -v            log every LLM prompt and response in full")
	fmt.Fprintln(w, "  -q            log stage results only")
	fmt.Fprintln(w, "  -regenerate   ignore the lock and rewrite every store and wrapper")
	fmt.Fprintf(w, "\nEvery run writes one file per LLM call to %s.\n", llm.TraceDirName)
}

func runCommand(target Target, opts Options, verbose, quiet bool) (runErr error) {
	logger := log.New(os.Stdout, logLevel(verbose, quiet))
	reporter := log.NewReporter(os.Stdout, logger)

	loadEnvFile(logger)

	started := time.Now()
	reporter.Start("Metacode run")
	// The outcome is reported through the named return: a run that ended on a
	// red suite closed with a green tick until this read the error it was
	// about to return.
	defer func() {
		logger.Infof("total time %s", time.Since(started).Round(time.Millisecond))
		reporter.EndStatus("Metacode run", runErr == nil)
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

	app, work, err := Scaffold(target, opts, reporter, logger, paths, paths.Root)
	if err != nil {
		return err
	}

	tracer := newLLMClient(logger, paths.Root)
	if tracer != nil {
		defer func() { reportUsage(logger, tracer) }()
	}

	var impl Implementer
	if tracer != nil {
		impl = target.NewImplementer(tracer, logger, &app, work, paths.Root)
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
	tests.Progress = log.NewSpinner(os.Stdout)

	_, verifyErr := stage(reporter, "Running tests", func() (struct{}, error) {
		return struct{}{}, Verify(context.Background(), tests, repairer, logger)
	})

	// The lock is written whether or not the suite passed, and only after the
	// suite has been attempted. Those are the same rule seen from two sides:
	// what must not be recorded is input the run never understood, because the
	// next run would then diff against a state that never existed. A red suite
	// is understood input, and recording it costs nothing, because the next
	// run observes the failures again and the repair loop unfreezes everything
	// anyway. See docs/proposals/lock-and-diff.md.
	if err := writeLock(logger, target, paths); err != nil {
		logger.Warnf("could not write %s: %s", lock.DirName, err)
	}

	if verifyErr != nil {
		return verifyErr
	}
	logger.Infof("tests passed (%s)", Strategy(repairer))

	return nil
}

// writeLock records the specs this run understood, so the next one can tell
// what changed.
func writeLock(logger log.Logger, target Target, paths spec.Paths) error {
	if err := lock.Write(paths, lock.Stamp{RulesHash: lock.HashRules(target.PromptRules)}); err != nil {
		return err
	}
	logger.Infof("recorded the specs in %s/%s", filepath.Base(paths.Metacode), lock.DirName)
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
func newLLMClient(logger log.Logger, projectDir string) *llm.Tracer {
	cfg, err := llm.ConfigFromEnv()
	if err != nil {
		logger.Warnf("LLM not configured: %s", err)
		logger.Warnf("set ANTHROPIC_API_KEY in a .env file (see .env.example) to enable generation, or METACODE_LLM_PROVIDER=openai with METACODE_LLM_BASE_URL and METACODE_LLM_API_KEY")
		return nil
	}

	logger.Infof("LLM: provider=%s model=%s max_tokens=%d", cfg.Provider, cfg.Model, cfg.MaxTokens)
	if err := llm.ResetTraceDir(projectDir); err != nil {
		logger.Warnf("could not clear the LLM trace directory: %s", err)
	}
	logger.Infof("LLM transcripts: %s", llm.TraceDirName)

	return llm.NewTracer(llm.NewClient(cfg, logger), logger, projectDir, os.Stdout)
}

// reportUsage closes a run with what it spent. It is the last thing printed,
// because "how many tokens did that cost" is the question a run raises and
// nothing else in the output answers.
func reportUsage(logger log.Logger, tracer *llm.Tracer) {
	calls := tracer.Calls()
	if calls == 0 {
		return
	}
	logger.Infof("LLM usage: %d call(s), %s", calls, tracer.Usage())
}

// stage runs one pipeline step under the reporter, so a step cannot be started
// without its result being reported.
func stage[T any](reporter *log.Reporter, name log.Stage, fn func() (T, error)) (T, error) {
	reporter.Start(name)
	out, err := fn()
	reporter.End(name, err)
	return out, err
}
