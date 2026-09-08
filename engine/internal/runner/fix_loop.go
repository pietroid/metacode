package runner

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/pietroid/metacode/engine/internal/llm"
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

	wrapperTasks := findWrapperTasksForScenario(tasks, scenarioID)
	if len(wrapperTasks) == 0 {
		fl.reportf("  no wrapper task found for scenario %q", scenarioID)
		return nil
	}

	testCode, err := os.ReadFile(filepath.Join(fl.ProjectDir, failure.File))
	if err != nil {
		return fmt.Errorf("read test file %q: %w", failure.File, err)
	}

	for _, task := range wrapperTasks {
		wrapperPath := filepath.Join(fl.ProjectDir, task.TargetFile)
		currentCode, err := os.ReadFile(wrapperPath)
		if err != nil {
			return fmt.Errorf("read wrapper file %q: %w", task.TargetFile, err)
		}

		fixTask := buildFixTask(task, string(testCode), failure.Message)
		newCode, err := fl.generate(ctx, fixTask, string(currentCode))
		if err != nil {
			return fmt.Errorf("generate fix for %s: %w", task.TargetFile, err)
		}

		if err := os.WriteFile(wrapperPath, []byte(newCode), 0644); err != nil {
			return fmt.Errorf("write wrapper file %q: %w", wrapperPath, err)
		}
		fl.reportf("  regenerated %s", task.TargetFile)
	}

	return nil
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
	return extractFixDartCode(raw)
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
	b.WriteString("\nCurrent wrapper code:\n")
	b.WriteString(code)
	b.WriteString("\nFix the wrapper code so the test passes. Return only the corrected Dart code in a ```dart fence.\n")
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

func findWrapperTasksForScenario(tasks []planner.Task, scenarioID string) []planner.Task {
	var out []planner.Task
	for _, task := range tasks {
		if task.Type == planner.TaskWrapper && task.ScenarioID == scenarioID {
			out = append(out, task)
		}
	}
	return out
}

var dartFence = regexp.MustCompile("```(?:dart)?\\s*\\n(?s)(.*?)\\n```")

func extractFixDartCode(raw string) (string, error) {
	matches := dartFence.FindAllStringSubmatch(raw, -1)
	if len(matches) == 0 {
		return "", fmt.Errorf("no dart code fence found")
	}
	return strings.TrimSpace(matches[len(matches)-1][1]), nil
}

func (fl *FixLoop) reportf(format string, args ...any) {
	if fl.Reporter == nil {
		return
	}
	fl.Reporter.Logf(format, args...)
}
