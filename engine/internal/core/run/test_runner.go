package run

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/pietroid/metacode/engine/internal/log"
)

// Executor creates an exec.Cmd. It matches the signature of exec.Command so
// tests can inject fake command implementations.
type Executor func(name string, arg ...string) *exec.Cmd

// TestRunner executes a project's test suite and parses the result.
type TestRunner struct {
	ProjectDir string
	// Command is the suite runner, as command and arguments. It comes from the
	// target, so this package does not know what language it is testing.
	Command  []string
	Executor Executor
	Logger   log.Logger
	// Progress animates the suite as it reports. A nil Progress runs silently,
	// which is what the tests of this package want.
	Progress *log.Spinner
}

// NewTestRunner creates a runner that executes command in projectDir.
func NewTestRunner(projectDir string, command []string, logger log.Logger) *TestRunner {
	if logger == nil {
		logger = log.Nop()
	}
	return &TestRunner{
		ProjectDir: projectDir,
		Command:    command,
		Executor:   exec.Command,
		Logger:     logger,
	}
}

// Run executes the test command and returns a structured TestResult.
func (r *TestRunner) Run(ctx context.Context) (TestResult, error) {
	executor := r.Executor
	if executor == nil {
		executor = exec.Command
	}

	command := r.Command
	if len(command) == 0 {
		return TestResult{}, fmt.Errorf("no test command configured")
	}
	cmd := executor(command[0], command[1:]...)
	if r.ProjectDir != "" {
		cmd.Dir = r.ProjectDir
	}

	var stdout, stderr bytes.Buffer
	progress := newTestProgress(r.Progress, r.Logger, r.ProjectDir)
	cmd.Stdout = io.MultiWriter(&stdout, progress)
	cmd.Stderr = io.MultiWriter(&stderr, progress)

	if r.Progress != nil {
		r.Progress.Start(strings.Join(command, " "))
	}

	if err := cmd.Start(); err != nil {
		r.stopProgress(progress, false)
		return TestResult{}, fmt.Errorf("start %s: %w", command[0], err)
	}

	// Wait for command completion, allowing context cancellation to kill it.
	waitErr := make(chan error, 1)
	go func() { waitErr <- cmd.Wait() }()

	select {
	case <-ctx.Done():
		_ = cmd.Process.Kill()
		<-waitErr
		r.stopProgress(progress, false)
		return TestResult{}, ctx.Err()
	case err := <-waitErr:
		result, runErr := r.result(stdout.String()+stderr.String(), err)
		r.stopProgress(progress, result.Success && runErr == nil)
		return result, runErr
	}
}

// result turns the finished command into a TestResult. A non-zero exit is a red
// suite, not a broken run: only a failure to execute the command at all is an
// error here.
func (r *TestRunner) result(output string, err error) (TestResult, error) {
	r.logOutput(output)

	result := TestResult{Success: err == nil, Output: output}
	if err != nil {
		exitErr, ok := err.(*exec.ExitError)
		if !ok {
			return result, fmt.Errorf("run %s: %w", r.Command[0], err)
		}
		result.Success = exitErr.ExitCode() == 0
	}
	if !result.Success {
		result.Failures = r.relativeFailures(parseFailures(output))
	}
	return result, nil
}

func (r *TestRunner) stopProgress(progress *testProgress, ok bool) {
	if r.Progress == nil {
		return
	}
	r.Progress.StopWith(ok, progress.summary())
}

// logOutput keeps the whole suite output at debug level. The run already sees
// each test as it reports and each failure by name, so the raw dump is for
// someone who asked for everything with -v.
func (r *TestRunner) logOutput(output string) {
	if r.Logger == nil {
		return
	}
	for _, line := range strings.Split(output, "\n") {
		if line != "" {
			r.Logger.Debugf("  %s", line)
		}
	}
}

var failureLine = regexp.MustCompile(`^\d+:\d+\s+[+\d]+\s+-\d+:\s+(.+?)\s+\[E\]`)

// fileAndName splits Flutter's "<path>_test.dart: <test name>" into its two
// halves. The path is matched greedily so a directory or scenario name
// containing a space still yields the whole path: matching \S+ instead
// silently truncated "increments from 1_test.dart" to "1_test.dart", and every
// failure then failed to map back to a scenario, which disabled the fix loop
// without reporting anything.
var fileAndName = regexp.MustCompile(`^(.*_test\.dart):\s*(.*)$`)

// relativeFailures rewrites failure paths to be relative to the project, since
// Flutter reports absolute paths and every consumer joins the path onto the
// project directory.
func (r *TestRunner) relativeFailures(failures []Failure) []Failure {
	for i, f := range failures {
		if !filepath.IsAbs(f.File) {
			continue
		}
		rel, err := filepath.Rel(r.ProjectDir, f.File)
		if err != nil {
			continue
		}
		failures[i].File = rel
	}
	return failures
}

func parseFailures(output string) []Failure {
	lines := strings.Split(output, "\n")
	var failures []Failure
	var current *Failure

	for _, line := range lines {
		if m := failureLine.FindStringSubmatch(line); m != nil {
			if current != nil {
				failures = append(failures, *current)
			}
			description := m[1]
			file := ""
			if fm := fileAndName.FindStringSubmatch(description); fm != nil {
				file = strings.TrimSpace(fm[1])
				description = strings.TrimSpace(fm[2])
			}
			current = &Failure{
				File:    file,
				Name:    description,
				Message: "",
			}
			continue
		}

		if current != nil {
			trimmed := strings.TrimSpace(line)
			if trimmed == "" {
				continue
			}
			// Stop collecting if we hit a summary or unrelated non-indented line.
			if !strings.HasPrefix(line, " ") && (strings.Contains(line, "passed") || strings.Contains(line, "failed")) {
				failures = append(failures, *current)
				current = nil
				continue
			}
			if current.Message != "" {
				current.Message += "\n"
			}
			current.Message += trimmed
		}
	}

	if current != nil {
		failures = append(failures, *current)
	}

	return failures
}
