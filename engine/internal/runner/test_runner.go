package runner

import (
	"bytes"
	"context"
	"fmt"
	"os/exec"
	"regexp"
	"strings"
)

// Executor creates an exec.Cmd. It matches the signature of exec.Command so
// tests can inject fake command implementations.
type Executor func(name string, arg ...string) *exec.Cmd

// TestRunner executes `flutter test` in a Flutter project and parses the result.
type TestRunner struct {
	ProjectDir string
	Executor   Executor
	Reporter   ProgressReporter
}

// ProgressReporter is the minimal reporter surface used by TestRunner.
type ProgressReporter interface {
	Logf(format string, args ...any)
}

// NewTestRunner creates a runner that executes `flutter test` in projectDir.
func NewTestRunner(projectDir string, reporter ProgressReporter) *TestRunner {
	return &TestRunner{
		ProjectDir: projectDir,
		Executor:   exec.Command,
		Reporter:   reporter,
	}
}

// Run executes the test command and returns a structured TestResult.
func (r *TestRunner) Run(ctx context.Context) (TestResult, error) {
	executor := r.Executor
	if executor == nil {
		executor = exec.Command
	}

	cmd := executor("flutter", "test")
	if r.ProjectDir != "" {
		cmd.Dir = r.ProjectDir
	}

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Start(); err != nil {
		return TestResult{}, fmt.Errorf("start flutter test: %w", err)
	}

	// Wait for command completion, allowing context cancellation to kill it.
	waitErr := make(chan error, 1)
	go func() { waitErr <- cmd.Wait() }()

	select {
	case <-ctx.Done():
		_ = cmd.Process.Kill()
		<-waitErr
		return TestResult{}, ctx.Err()
	case err := <-waitErr:
		output := stdout.String() + stderr.String()
		r.logOutput(output)

		result := TestResult{
			Success: err == nil,
			Output:  output,
		}
		if err != nil {
			if exitErr, ok := err.(*exec.ExitError); ok {
				result.Success = exitErr.ExitCode() == 0
			} else {
				return result, fmt.Errorf("run flutter test: %w", err)
			}
		}
		if !result.Success {
			result.Failures = parseFailures(output)
		}
		return result, nil
	}
}

func (r *TestRunner) logOutput(output string) {
	if r.Reporter == nil {
		return
	}
	for _, line := range strings.Split(output, "\n") {
		if line != "" {
			r.Reporter.Logf("  %s", line)
		}
	}
}

var failureLine = regexp.MustCompile(`^\d+:\d+\s+[+\d]+\s+-\d+:\s+(.+?)\s+\[E\]`)
var fileInLine = regexp.MustCompile(`(\S+_test\.dart)`)

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
			if fm := fileInLine.FindStringSubmatch(description); fm != nil {
				file = fm[1]
				description = strings.TrimSpace(strings.Replace(description, file, "", 1))
				description = strings.TrimPrefix(description, ":")
				description = strings.TrimSpace(description)
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
