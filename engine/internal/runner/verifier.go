package runner

import (
	"context"
	"fmt"
	"strings"

	"github.com/pietroid/metacode/engine/internal/llm"
	"github.com/pietroid/metacode/engine/internal/planner"
)

// Verifier runs the generated tests and reports whether the project is good.
// A verifier may repair the project between runs.
type Verifier interface {
	// Name identifies the strategy for reporting.
	Name() string
	Run(ctx context.Context, tasks []planner.Task) error
}

// NewVerifier selects the verification strategy. A nil client means no LLM is
// configured, so the tests are run once and failures are reported as-is;
// otherwise failures feed the fix loop. This is the only place the choice is
// made.
func NewVerifier(runner *TestRunner, client llm.Client, projectDir string, reporter ProgressReporter) Verifier {
	if client == nil {
		return &singleRun{runner: runner}
	}
	return &FixLoop{
		MaxIterations: 3,
		Runner:        runner,
		Client:        client,
		ProjectDir:    projectDir,
		Reporter:      reporter,
	}
}

// singleRun runs the test suite once and fails on the first red suite.
type singleRun struct {
	runner *TestRunner
}

func (s *singleRun) Name() string { return "single run" }

func (s *singleRun) Run(ctx context.Context, _ []planner.Task) error {
	result, err := s.runner.Run(ctx)
	if err != nil {
		return err
	}
	if result.Success {
		return nil
	}
	if unimplemented := unimplementedActions(result.Failures); len(unimplemented) > 0 {
		return fmt.Errorf(
			"tests failed: %d failure(s), %d of them because store actions have no implementation yet.\n"+
				"Store action bodies are business logic and come from the behavior scenarios via the fix loop, "+
				"which needs an LLM. Set ANTHROPIC_API_KEY in a .env file, or implement the actions by hand",
			len(result.Failures), len(unimplemented))
	}
	return fmt.Errorf("tests failed: %d failure(s)", len(result.Failures))
}

// unimplementedActions returns the failures caused by a scaffolded store action
// that nothing has filled in yet, as opposed to genuinely wrong code.
func unimplementedActions(failures []Failure) []Failure {
	var out []Failure
	for _, f := range failures {
		if strings.Contains(f.Message, "UnimplementedError") {
			out = append(out, f)
		}
	}
	return out
}
