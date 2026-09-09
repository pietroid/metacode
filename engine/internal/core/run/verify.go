package run

import (
	"context"
	"fmt"
	"strings"

	"github.com/pietroid/metacode/engine/internal/log"
)

// Verify runs the generated tests and, when a repairer is supplied, fixes what
// fails until the suite is green or the iteration budget runs out.
//
// A nil repairer means no LLM is configured: the suite runs once and the
// failures are reported as they are. That used to be a second Verifier
// implementation behind an interface, chosen by a constructor, with a Name()
// method whose only reader was a log line.
func Verify(ctx context.Context, runner *TestRunner, repairer Repairer, logger log.Logger) error {
	if repairer == nil {
		return runOnce(ctx, runner)
	}
	loop := &FixLoop{
		MaxIterations: defaultFixIterations,
		Runner:        runner,
		Repairer:      repairer,
		Logger:        logger,
	}
	return loop.Run(ctx)
}

// Strategy names what Verify will do, for the run log.
func Strategy(repairer Repairer) string {
	if repairer == nil {
		return "single run"
	}
	return "fix loop"
}

// runOnce runs the suite and fails on the first red suite.
func runOnce(ctx context.Context, runner *TestRunner) error {
	result, err := runner.Run(ctx)
	if err != nil {
		return err
	}
	if result.Success {
		return nil
	}
	if unimplemented := unimplementedActions(result.Failures); len(unimplemented) > 0 {
		return fmt.Errorf(
			"tests failed: %d failure(s), %d of them because store actions have no implementation yet.\n"+
				"Store action bodies are business logic and come from the behavior scenarios via the implement "+
				"stage, which needs an LLM. Set ANTHROPIC_API_KEY in a .env file, or implement the actions by hand",
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
