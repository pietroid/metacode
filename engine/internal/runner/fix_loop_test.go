package runner

import (
	"context"
	"fmt"
	"os/exec"
	"strings"
	"testing"
)

// fakeRepairer records what the loop hands it, so a test can assert on how many
// requests a run would make and what each one saw.
type fakeRepairer struct {
	calls          int
	failuresPerRun []int
	iterations     []int
}

func (f *fakeRepairer) Repair(_ context.Context, iteration int, failures []Failure) error {
	f.calls++
	f.failuresPerRun = append(f.failuresPerRun, len(failures))
	f.iterations = append(f.iterations, iteration)
	return nil
}

var _ Repairer = (*fakeRepairer)(nil)

func makeFakeExecutor(outputs []string, exitCodes []int) Executor {
	idx := 0
	return func(name string, arg ...string) *exec.Cmd {
		output := outputs[idx]
		code := exitCodes[idx]
		if idx < len(outputs)-1 {
			idx++
		}
		script := fmt.Sprintf("echo %q; exit %d", output, code)
		return exec.Command("sh", "-c", script)
	}
}

func newLoop(maxIter int, repairer Repairer, outputs []string, codes []int) *FixLoop {
	return &FixLoop{
		MaxIterations: maxIter,
		Runner: &TestRunner{
			ProjectDir: "",
			Executor:   makeFakeExecutor(outputs, codes),
			Reporter:   &fakeReporter{},
		},
		Repairer: repairer,
		Reporter: &fakeReporter{},
	}
}

func TestFixLoopStopsOnFirstPass(t *testing.T) {
	repairer := &fakeRepairer{}
	loop := newLoop(3, repairer, []string{"00:00 +1: All tests passed!"}, []int{0})

	if err := loop.Run(context.Background()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if repairer.calls != 0 {
		t.Errorf("expected no repair requests when tests pass, got %d", repairer.calls)
	}
}

// TestFixLoopSendsEveryFailureInOneRequest is the reason the loop no longer
// walks failures: three failing tests are one request, not three. Repairing
// them one at a time meant each fix overwrote the file the previous one had
// just written, without having seen why.
func TestFixLoopSendsEveryFailureInOneRequest(t *testing.T) {
	failureOutput := strings.Join([]string{
		"00:01 +0 -1: test/a_test.dart: increments from 0 [E]",
		"  expected 1",
		"00:01 +0 -2: test/b_test.dart: increments from 1 [E]",
		"  expected 2",
		"00:01 +0 -3: test/c_test.dart: decrements from 1 [E]",
		"  expected 0",
		"",
		"Some tests failed.",
	}, "\n")

	repairer := &fakeRepairer{}
	loop := newLoop(3, repairer, []string{failureOutput, "00:00 +3: fixed"}, []int{1, 0})

	if err := loop.Run(context.Background()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if repairer.calls != 1 {
		t.Fatalf("expected 1 repair request, got %d", repairer.calls)
	}
	if repairer.failuresPerRun[0] != 3 {
		t.Errorf("expected all 3 failures in the one request, got %d", repairer.failuresPerRun[0])
	}
}

func TestFixLoopRespectsMaxIterations(t *testing.T) {
	failureOutput := strings.Join([]string{
		"00:01 +0 -1: test/counter_test.dart: increment [E]",
		"  fail",
	}, "\n")

	repairer := &fakeRepairer{}
	loop := newLoop(3, repairer, []string{failureOutput, failureOutput, failureOutput}, []int{1, 1, 1})

	err := loop.Run(context.Background())
	if err == nil {
		t.Fatal("expected error after max iterations")
	}
	if !strings.Contains(err.Error(), "fix loop exhausted") {
		t.Errorf("expected exhausted error, got %v", err)
	}
	// Three test runs, and no repair after the last one: repairing without
	// re-running would report a fix nothing had verified.
	if repairer.calls != 2 {
		t.Errorf("expected 2 repair requests for 3 test runs, got %d", repairer.calls)
	}
	for i, got := range repairer.iterations {
		if got != i+1 {
			t.Errorf("repair %d was told it was iteration %d", i+1, got)
		}
	}
}
