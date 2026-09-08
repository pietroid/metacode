package runner

import (
	"context"
	"fmt"

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
	if !result.Success {
		return fmt.Errorf("tests failed: %d failure(s)", len(result.Failures))
	}
	return nil
}
