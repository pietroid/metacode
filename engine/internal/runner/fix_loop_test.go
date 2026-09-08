package runner

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/llm"
	"github.com/pietroid/metacode/engine/internal/planner"
)

type fakeLLMClient struct {
	calls int
}

func (f *fakeLLMClient) Complete(ctx context.Context, prompt string) (string, error) {
	f.calls++
	return "```dart\nclass FixedWrapper extends StatelessWidget {\n  const FixedWrapper({super.key});\n  @override\n  Widget build(BuildContext context) => Container();\n}\n```", nil
}

var _ llm.Client = (*fakeLLMClient)(nil)

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

func setupFixProject(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()

	if err := os.MkdirAll(filepath.Join(dir, "test"), 0755); err != nil {
		t.Fatalf("create test dir: %v", err)
	}
	if err := os.MkdirAll(filepath.Join(dir, "lib", "wrappers"), 0755); err != nil {
		t.Fatalf("create wrappers dir: %v", err)
	}

	testCode := `import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('increment changes state', (tester) async {});
}
`
	if err := os.WriteFile(filepath.Join(dir, "test", "counter_test.dart"), []byte(testCode), 0644); err != nil {
		t.Fatalf("write test file: %v", err)
	}

	wrapperCode := `import 'package:flutter/material.dart';

class CounterWrapper extends StatelessWidget {
  const CounterWrapper({super.key});
  @override
  Widget build(BuildContext context) => Container();
}
`
	if err := os.WriteFile(filepath.Join(dir, "lib", "wrappers", "counter_wrapper.dart"), []byte(wrapperCode), 0644); err != nil {
		t.Fatalf("write wrapper file: %v", err)
	}

	return dir
}

func TestFixLoopStopsOnFirstPass(t *testing.T) {
	dir := setupFixProject(t)
	client := &fakeLLMClient{}

	loop := &FixLoop{
		MaxIterations: 3,
		Runner: &TestRunner{
			ProjectDir: dir,
			Executor:   makeFakeExecutor([]string{"00:00 +1: All tests passed!"}, []int{0}),
			Reporter:   &fakeReporter{},
		},
		Client:     client,
		ProjectDir: dir,
	}

	tasks := []planner.Task{
		{ID: "test-1", Type: planner.TaskTest, TargetFile: "test/counter_test.dart", ScenarioID: "s1"},
		{ID: "wrapper-1", Type: planner.TaskWrapper, TargetFile: "lib/wrappers/counter_wrapper.dart", ScenarioID: "s1"},
	}

	if err := loop.Run(context.Background(), tasks); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if client.calls != 0 {
		t.Errorf("expected no LLM calls when tests pass, got %d", client.calls)
	}
}

func TestFixLoopRegeneratesAndRetries(t *testing.T) {
	dir := setupFixProject(t)
	client := &fakeLLMClient{}

	failureOutput := strings.Join([]string{
		"00:01 +0 -1: test/counter_test.dart: increment changes state [E]",
		"  expected 1",
		"",
		"Some tests failed.",
	}, "\n")

	loop := &FixLoop{
		MaxIterations: 3,
		Runner: &TestRunner{
			ProjectDir: dir,
			Executor:   makeFakeExecutor([]string{failureOutput, "00:00 +1: fixed"}, []int{1, 0}),
			Reporter:   &fakeReporter{},
		},
		Client:     client,
		ProjectDir: dir,
	}

	tasks := []planner.Task{
		{ID: "test-1", Type: planner.TaskTest, TargetFile: "test/counter_test.dart", ScenarioID: "s1"},
		{ID: "wrapper-1", Type: planner.TaskWrapper, TargetFile: "lib/wrappers/counter_wrapper.dart", ScenarioID: "s1"},
	}

	if err := loop.Run(context.Background(), tasks); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if client.calls != 1 {
		t.Errorf("expected 1 LLM call, got %d", client.calls)
	}

	written, err := os.ReadFile(filepath.Join(dir, "lib", "wrappers", "counter_wrapper.dart"))
	if err != nil {
		t.Fatalf("read wrapper: %v", err)
	}
	if !strings.Contains(string(written), "FixedWrapper") {
		t.Errorf("expected wrapper to be regenerated, got:\n%s", string(written))
	}
}

func TestFixLoopRespectsMaxIterations(t *testing.T) {
	dir := setupFixProject(t)
	client := &fakeLLMClient{}

	failureOutput := strings.Join([]string{
		"00:01 +0 -1: test/counter_test.dart: increment [E]",
		"  fail",
	}, "\n")

	loop := &FixLoop{
		MaxIterations: 2,
		Runner: &TestRunner{
			ProjectDir: dir,
			Executor:   makeFakeExecutor([]string{failureOutput, failureOutput, failureOutput}, []int{1, 1, 1}),
			Reporter:   &fakeReporter{},
		},
		Client:     client,
		ProjectDir: dir,
	}

	tasks := []planner.Task{
		{ID: "test-1", Type: planner.TaskTest, TargetFile: "test/counter_test.dart", ScenarioID: "s1"},
		{ID: "wrapper-1", Type: planner.TaskWrapper, TargetFile: "lib/wrappers/counter_wrapper.dart", ScenarioID: "s1"},
	}

	err := loop.Run(context.Background(), tasks)
	if err == nil {
		t.Fatal("expected error after max iterations")
	}
	if !strings.Contains(err.Error(), "fix loop exhausted") {
		t.Errorf("expected exhausted error, got %v", err)
	}
	if client.calls != 2 {
		t.Errorf("expected 2 LLM calls (one per iteration), got %d", client.calls)
	}
}

func TestFixLoopUsesCustomGenerator(t *testing.T) {
	dir := setupFixProject(t)
	client := &fakeLLMClient{}
	generatorCalls := 0

	failureOutput := strings.Join([]string{
		"00:01 +0 -1: test/counter_test.dart: increment [E]",
		"  fail",
	}, "\n")

	loop := &FixLoop{
		MaxIterations: 3,
		Runner: &TestRunner{
			ProjectDir: dir,
			Executor:   makeFakeExecutor([]string{failureOutput, "00:00 +1: fixed"}, []int{1, 0}),
			Reporter:   &fakeReporter{},
		},
		Client: client,
		Generator: func(ctx context.Context, task planner.Task, code string) (string, error) {
			generatorCalls++
			if !strings.Contains(task.PromptContext, "Failing test:") {
				t.Errorf("expected fix task prompt context to contain failing test")
			}
			return "class CustomFixed extends StatelessWidget { @override Widget build(BuildContext context) => Container(); }", nil
		},
		ProjectDir: dir,
	}

	tasks := []planner.Task{
		{ID: "test-1", Type: planner.TaskTest, TargetFile: "test/counter_test.dart", ScenarioID: "s1"},
		{ID: "wrapper-1", Type: planner.TaskWrapper, TargetFile: "lib/wrappers/counter_wrapper.dart", ScenarioID: "s1"},
	}

	if err := loop.Run(context.Background(), tasks); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if generatorCalls != 1 {
		t.Errorf("expected 1 generator call, got %d", generatorCalls)
	}
	if client.calls != 0 {
		t.Errorf("expected no LLM calls when generator is provided, got %d", client.calls)
	}
}

func TestBuildFixPromptContainsRequiredSections(t *testing.T) {
	task := planner.Task{
		PromptContext: "Scenario: s1\nWhen: tap\nThen: value is 1\n",
	}
	prompt := buildFixPrompt(task, "class Wrapper {}")

	required := []string{
		"The following Flutter test is failing.",
		"Current contents of ",
		"Rewrite this file so the test passes.",
		"a wrapper must not call emit",
		"class Wrapper {}",
	}
	for _, r := range required {
		if !strings.Contains(prompt, r) {
			t.Errorf("expected prompt to contain %q, got:\n%s", r, prompt)
		}
	}
}

// TestFindRepairableTasksIncludesStores pins the fix for a generated wrapper
// that reached through cubit.emit to change state. The fix loop could only
// rewrite wrappers, so when the Cubit was missing the method a scenario needed,
// the only file the loop was allowed to touch was the wrong one.
func TestFindRepairableTasksIncludesStores(t *testing.T) {
	tasks := []planner.Task{
		{ID: "wrapper-a", Type: planner.TaskWrapper, ScenarioID: "s1", TargetFile: "lib/wrappers/a_wrapper.dart"},
		{ID: "store-a", Type: planner.TaskStore, ScenarioID: "s1", TargetFile: "lib/stores/a_cubit.dart"},
		{ID: "store-a-dup", Type: planner.TaskStore, ScenarioID: "s1", TargetFile: "lib/stores/a_cubit.dart"},
		{ID: "wrapper-b", Type: planner.TaskWrapper, ScenarioID: "s2", TargetFile: "lib/wrappers/b_wrapper.dart"},
	}

	got := findRepairableTasks(tasks, "s1")
	if len(got) != 2 {
		t.Fatalf("expected 2 repairable tasks, got %d: %+v", len(got), got)
	}
	// Business logic first: a wiring fix should be judged against a store that
	// has already had its chance to be right.
	if got[0].TargetFile != "lib/stores/a_cubit.dart" {
		t.Errorf("expected the store first, got %q", got[0].TargetFile)
	}
	if got[1].TargetFile != "lib/wrappers/a_wrapper.dart" {
		t.Errorf("expected the wrapper second, got %q", got[1].TargetFile)
	}
}
