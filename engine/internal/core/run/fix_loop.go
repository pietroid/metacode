package run

import (
	"context"
	"fmt"
	"strings"

	"github.com/pietroid/metacode/engine/internal/log"
)

// Repairer rewrites the app so a set of failing tests passes. One call per
// iteration, carrying every failure of that
//
// The loop does not know, and no longer tries to work out, which layer a given
// failure belongs to. Mapping a failing test back to "the wrapper or the store
// it might have come from" was guesswork that cost one request per candidate
// file per failure, and each of those requests saw a single test.
type Repairer interface {
	Repair(ctx context.Context, iteration int, failures []Failure) error
}

// defaultFixIterations is how many times the suite runs before the loop gives
// up: the first run, then two repaired runs.
const defaultFixIterations = 3

// FixLoop runs the tests, hands every failure to the Repairer, and runs them
// again.
type FixLoop struct {
	MaxIterations int
	Runner        *TestRunner
	Repairer      Repairer
	Logger        log.Logger
}

// Run executes the test/fix loop until all tests pass or the maximum number of
// iterations is reached.
func (fl *FixLoop) Run(ctx context.Context) error {
	maxIter := fl.MaxIterations
	if maxIter <= 0 {
		maxIter = defaultFixIterations
	}

	var last TestResult
	for i := 0; i < maxIter; i++ {
		result, err := fl.Runner.Run(ctx)
		if err != nil {
			return fmt.Errorf("test run: %w", err)
		}
		last = result

		if result.Success {
			fl.reportf("all tests passed after %d test run(s)", i+1)
			return nil
		}

		fl.reportf("%d failing test(s):", len(result.Failures))
		for _, f := range result.Failures {
			fl.reportf("  - %s: %s", f.File, f.Name)
		}

		if i == maxIter-1 {
			break
		}

		fl.reportf("--- fix iteration %d of %d ---", i+1, maxIter-1)
		if err := fl.Repairer.Repair(ctx, i+1, result.Failures); err != nil {
			return fmt.Errorf("repair: %w", err)
		}
	}

	var msgs []string
	for _, f := range last.Failures {
		msgs = append(msgs, fmt.Sprintf("%s: %s", f.File, f.Name))
	}
	return fmt.Errorf("fix loop exhausted after %d test run(s); remaining failures:\n%s", maxIter, strings.Join(msgs, "\n"))
}

func (fl *FixLoop) reportf(format string, args ...any) {
	if fl.Logger == nil {
		return
	}
	fl.Logger.Infof(format, args...)
}
