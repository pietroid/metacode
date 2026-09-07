package runner

import (
	"context"
	"fmt"
	"io"
	"os/exec"
	"strings"
	"testing"
)

type fakeReporter struct {
	lines []string
}

func (f *fakeReporter) Logf(format string, args ...any) {
	f.lines = append(f.lines, fmt.Sprintf(format, args...))
}

func fakeExecutor(output string, exitCode int) Executor {
	return func(name string, arg ...string) *exec.Cmd {
		cs := []string{"-c", fmt.Sprintf("echo %q; exit %d", output, exitCode)}
		return exec.Command("sh", cs...)
	}
}

func fakeExecutorWithStderr(stdout, stderr string, exitCode int) Executor {
	return func(name string, arg ...string) *exec.Cmd {
		script := fmt.Sprintf("echo %q; echo %q >&2; exit %d", stdout, stderr, exitCode)
		return exec.Command("sh", "-c", script)
	}
}

func TestRunAllTestsPass(t *testing.T) {
	output := "00:00 +1: All tests passed!"
	runner := &TestRunner{
		ProjectDir: t.TempDir(),
		Executor:   fakeExecutor(output, 0),
		Reporter:   &fakeReporter{},
	}

	result, err := runner.Run(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !result.Success {
		t.Errorf("expected success, got failure")
	}
	if !strings.Contains(result.Output, "All tests passed!") {
		t.Errorf("expected output to contain test output, got:\n%s", result.Output)
	}
	if len(result.Failures) != 0 {
		t.Errorf("expected no failures, got %d", len(result.Failures))
	}
}

func TestRunCapturesFailingTest(t *testing.T) {
	output := strings.Join([]string{
		"00:01 +0 -1: counter_test.dart: increment changes state [E]",
		"  Expected: <1>",
		"  Actual: <0>",
		"",
		"00:01 +0 -1: Some tests failed.",
	}, "\n")

	runner := &TestRunner{
		ProjectDir: t.TempDir(),
		Executor:   fakeExecutor(output, 1),
		Reporter:   &fakeReporter{},
	}

	result, err := runner.Run(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result.Success {
		t.Errorf("expected failure")
	}
	if len(result.Failures) != 1 {
		t.Fatalf("expected 1 failure, got %d", len(result.Failures))
	}
	f := result.Failures[0]
	if f.File != "counter_test.dart" {
		t.Errorf("expected file counter_test.dart, got %q", f.File)
	}
	if f.Name != "increment changes state" {
		t.Errorf("expected name 'increment changes state', got %q", f.Name)
	}
	if !strings.Contains(f.Message, "Expected: <1>") {
		t.Errorf("expected message to contain expected value, got:\n%s", f.Message)
	}
}

func TestRunCapturesStderr(t *testing.T) {
	runner := &TestRunner{
		ProjectDir: t.TempDir(),
		Executor:   fakeExecutorWithStderr("stdout line", "stderr line", 0),
		Reporter:   &fakeReporter{},
	}

	result, err := runner.Run(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(result.Output, "stderr line") {
		t.Errorf("expected output to include stderr, got:\n%s", result.Output)
	}
}

func TestRunLogsOutput(t *testing.T) {
	reporter := &fakeReporter{}
	runner := &TestRunner{
		ProjectDir: t.TempDir(),
		Executor:   fakeExecutor("test output", 0),
		Reporter:   reporter,
	}

	_, err := runner.Run(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	found := false
	for _, line := range reporter.lines {
		if strings.Contains(line, "test output") {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("expected reporter to log test output, got: %v", reporter.lines)
	}
}

func TestRunRespectsContextCancellation(t *testing.T) {
	runner := &TestRunner{
		ProjectDir: t.TempDir(),
		Executor: func(name string, arg ...string) *exec.Cmd {
			// Start a command that sleeps long enough to be cancelled.
			return exec.Command("sh", "-c", "sleep 10")
		},
		Reporter: &fakeReporter{},
	}

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := runner.Run(ctx)
	if err != context.Canceled {
		t.Errorf("expected context.Canceled, got %v", err)
	}
}

func TestParseFailuresMultipleTests(t *testing.T) {
	output := strings.Join([]string{
		"00:01 +0 -1: a_test.dart: first [E]",
		"  first failure",
		"00:01 +0 -2: b_test.dart: second [E]",
		"  second failure",
		"",
		"Some tests failed.",
	}, "\n")

	failures := parseFailures(output)
	if len(failures) != 2 {
		t.Fatalf("expected 2 failures, got %d", len(failures))
	}
	if failures[0].File != "a_test.dart" || failures[0].Name != "first" {
		t.Errorf("unexpected first failure: %+v", failures[0])
	}
	if failures[1].File != "b_test.dart" || failures[1].Name != "second" {
		t.Errorf("unexpected second failure: %+v", failures[1])
	}
}

var _ io.Writer = (*strings.Builder)(nil)
