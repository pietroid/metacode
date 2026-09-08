package runner

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/pietroid/metacode/engine/internal/llm"
	"github.com/pietroid/metacode/engine/internal/modules/codegen"
	"github.com/pietroid/metacode/engine/internal/modules/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/planner"
)

// FixLoop iteratively regenerates wrapper code when Flutter tests fail.
type FixLoop struct {
	MaxIterations int
	Runner        *TestRunner
	Client        llm.Client
	Generator     func(ctx context.Context, task planner.Task, code string) (string, error)
	ProjectDir    string
	Reporter      ProgressReporter
}

// Name implements Verifier.
func (fl *FixLoop) Name() string { return "fix loop" }

// Run executes the test/fix loop until all tests pass or the maximum number
// of iterations is reached.
func (fl *FixLoop) Run(ctx context.Context, tasks []planner.Task) error {
	maxIter := fl.MaxIterations
	if maxIter <= 0 {
		maxIter = 3
	}

	for i := 0; i < maxIter; i++ {
		if i > 0 {
			fl.reportf("--- Fix iteration %d ---", i+1)
		}

		result, err := fl.Runner.Run(ctx)
		if err != nil {
			return fmt.Errorf("test run: %w", err)
		}

		if result.Success {
			fl.reportf("All tests passed after %d iteration(s)", i+1)
			return nil
		}

		fl.reportf("Tests failed (%d failure(s))", len(result.Failures))
		for _, f := range result.Failures {
			fl.reportf("  - %s: %s", f.File, f.Name)
		}

		if err := fl.fixFailures(ctx, tasks, result.Failures); err != nil {
			return fmt.Errorf("fix failures: %w", err)
		}
	}

	result, err := fl.Runner.Run(ctx)
	if err != nil {
		return fmt.Errorf("final test run: %w", err)
	}
	if !result.Success {
		var msgs []string
		for _, f := range result.Failures {
			msgs = append(msgs, fmt.Sprintf("%s: %s", f.File, f.Name))
		}
		return fmt.Errorf("fix loop exhausted after %d iteration(s); remaining failures:\n%s", maxIter, strings.Join(msgs, "\n"))
	}

	return nil
}

func (fl *FixLoop) fixFailures(ctx context.Context, tasks []planner.Task, failures []Failure) error {
	for _, failure := range failures {
		if err := fl.fixFailure(ctx, tasks, failure); err != nil {
			return err
		}
	}
	return nil
}

func (fl *FixLoop) fixFailure(ctx context.Context, tasks []planner.Task, failure Failure) error {
	scenarioID, err := findScenarioIDForTest(tasks, failure.File)
	if err != nil {
		// If we cannot map the failure to a scenario, skip it.
		fl.reportf("  could not map failure to scenario: %v", err)
		return nil
	}

	// A failing scenario can be wrong in two places: the wiring in the wrapper,
	// or the business logic in the store action it triggers. Both are candidates.
	repairable := findRepairableTasks(tasks, scenarioID)
	if len(repairable) == 0 {
		fl.reportf("  no wrapper or store task found for scenario %q", scenarioID)
		return nil
	}

	testCode, err := os.ReadFile(filepath.Join(fl.ProjectDir, failure.File))
	if err != nil {
		return fmt.Errorf("read test file %q: %w", failure.File, err)
	}

	for _, task := range repairable {
		targetPath := filepath.Join(fl.ProjectDir, task.TargetFile)
		currentCode, err := os.ReadFile(targetPath)
		if err != nil {
			return fmt.Errorf("read %q: %w", task.TargetFile, err)
		}

		fixTask := buildFixTask(task, string(testCode), failure.Message)
		newCode, err := fl.generate(ctx, fixTask, string(currentCode))
		if err != nil {
			return fmt.Errorf("generate fix for %s: %w", task.TargetFile, err)
		}

		// A fix that is not a plausible Dart file is discarded rather than
		// written. Without this the loop wrote whatever came back: a fix for a
		// wrapper once arrived as two bare Cubit methods with no class, and
		// replaced the wrapper with a file that could not compile.
		if err := dart.Validate(newCode); err != nil {
			fl.reportf("  discarded fix for %s: %s", task.TargetFile, err)
			continue
		}

		if err := os.WriteFile(targetPath, []byte(preserveMarker(string(currentCode), newCode)), 0644); err != nil {
			return fmt.Errorf("write %q: %w", targetPath, err)
		}
		fl.reportf("  regenerated %s", task.TargetFile)
	}

	return nil
}

// preserveMarker keeps the generated-file header when a fix drops it. Stale
// output is pruned by that marker, so an unmarked file is one nothing can
// clean up later.
func preserveMarker(oldCode, newCode string) string {
	if strings.Contains(newCode, codegen.Marker) {
		return newCode
	}
	for _, line := range strings.Split(oldCode, "\n") {
		if strings.Contains(line, codegen.Marker) {
			return line + "\n" + newCode
		}
	}
	return newCode
}

func (fl *FixLoop) generate(ctx context.Context, task planner.Task, code string) (string, error) {
	if fl.Generator != nil {
		return fl.Generator(ctx, task, code)
	}
	if fl.Client == nil {
		return "", fmt.Errorf("no generator or client configured")
	}
	prompt := buildFixPrompt(task, code)
	raw, err := fl.Client.Complete(ctx, prompt)
	if err != nil {
		return "", err
	}
	return dart.ExtractCode(raw)
}

func buildFixTask(task planner.Task, testCode, message string) planner.Task {
	ctx := strings.Builder{}
	ctx.WriteString(task.PromptContext)
	ctx.WriteString(fmt.Sprintf("\nFailing test:\n%s\n", testCode))
	ctx.WriteString(fmt.Sprintf("Failure message:\n%s\n", message))

	return planner.Task{
		ID:              "fix-" + task.ID,
		Type:            planner.TaskFix,
		TargetFile:      task.TargetFile,
		ScenarioID:      task.ScenarioID,
		Description:     fmt.Sprintf("Fix %s so %s passes", task.TargetFile, task.ScenarioID),
		PromptContext:   ctx.String(),
		ExpectedOutcome: fmt.Sprintf("Test for scenario %q passes", task.ScenarioID),
	}
}

func buildFixPrompt(task planner.Task, code string) string {
	var b strings.Builder
	b.WriteString("The following Flutter test is failing.\n")
	b.WriteString(task.PromptContext)
	b.WriteString("\nCurrent contents of ")
	b.WriteString(task.TargetFile)
	b.WriteString(":\n")
	b.WriteString(code)
	b.WriteString("\nRewrite this file so the test passes.\n")
	b.WriteString("Keep every declaration the file already has, including methods this test does not exercise.\n")
	b.WriteString("Business rules belong in the store, not in a widget: a wrapper must not call emit.\n")
	b.WriteString("Return only the corrected Dart code for the whole file, in a ```dart fence.\n")
	return b.String()
}

func findScenarioIDForTest(tasks []planner.Task, testFile string) (string, error) {
	name := filepath.Base(testFile)
	for _, task := range tasks {
		if task.Type != planner.TaskTest {
			continue
		}
		if filepath.Base(task.TargetFile) == name {
			return task.ScenarioID, nil
		}
	}
	return "", fmt.Errorf("no test task for file %q", testFile)
}

// findRepairableTasks returns the tasks whose output the fix loop may rewrite
// for a failing scenario: the store actions the scenario drives, then the
// wrappers that wire it. Stores come first so a wiring fix is judged against
// business logic that has already had its chance to be right.
//
// The same file can back several tasks, so each target is offered once.
func findRepairableTasks(tasks []planner.Task, scenarioID string) []planner.Task {
	var out []planner.Task
	seen := make(map[string]bool)

	for _, wanted := range []planner.TaskType{planner.TaskStore, planner.TaskWrapper} {
		for _, task := range tasks {
			if task.Type != wanted || task.ScenarioID != scenarioID {
				continue
			}
			if seen[task.TargetFile] {
				continue
			}
			seen[task.TargetFile] = true
			out = append(out, task)
		}
	}
	return out
}

func (fl *FixLoop) reportf(format string, args ...any) {
	if fl.Reporter == nil {
		return
	}
	fl.Reporter.Logf(format, args...)
}
