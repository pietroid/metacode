package flutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/planner"
)

func TestGenerateTestsCreatesFiles(t *testing.T) {
	app := counterAppFullIR()
	dir := setupGeneratedFiles(t, app)

	tasks, err := planner.Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}
	if err := GenerateTests(app, tasks, dir); err != nil {
		t.Fatalf("generate tests failed: %v", err)
	}

	for _, name := range []string{"test/counterStore_increments from 0_test.dart", "test/counterStore_Show counter value on the home page_test.dart"} {
		path := filepath.Join(dir, name)
		if _, err := os.Stat(path); err != nil {
			t.Errorf("expected %s to exist: %v", name, err)
		}
	}
}

func TestGenerateTestsWidgetTestImports(t *testing.T) {
	app := counterAppFullIR()
	dir := setupGeneratedFiles(t, app)

	tasks, err := planner.Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	if err := GenerateTests(app, tasks, dir); err != nil {
		t.Fatalf("generate tests failed: %v", err)
	}

	path := filepath.Join(dir, "test", "counterStore_Show counter value on the home page_test.dart")
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read test file: %v", err)
	}

	want := []string{
		"import 'package:flutter/material.dart';",
		"import 'package:flutter_bloc/flutter_bloc.dart';",
		"import 'package:flutter_test/flutter_test.dart';",
		"import 'package:counter_app/stores/counter_cubit.dart';",
		"import 'package:counter_app/stores/counter_state.dart';",
		"import 'package:counter_app/wrappers/home_page_wrapper.dart';",
	}
	for _, imp := range want {
		if !strings.Contains(string(content), imp) {
			t.Errorf("expected test to import %q, got:\n%s", imp, string(content))
		}
	}
}

func TestGenerateTestsWidgetTestSeedsAndAsserts(t *testing.T) {
	app := counterAppFullIR()
	dir := setupGeneratedFiles(t, app)

	tasks, err := planner.Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	if err := GenerateTests(app, tasks, dir); err != nil {
		t.Fatalf("generate tests failed: %v", err)
	}

	path := filepath.Join(dir, "test", "counterStore_Show counter value on the home page_test.dart")
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read test file: %v", err)
	}

	if !strings.Contains(string(content), "cubit.emit(CounterState(value: 5))") {
		t.Errorf("expected test to seed cubit with value 5, got:\n%s", string(content))
	}
	if !strings.Contains(string(content), "expect(find.text('5'), findsOneWidget)") {
		t.Errorf("expected test to assert text '5' is found, got:\n%s", string(content))
	}
}

func TestGenerateTestsWidgetTestTapsButton(t *testing.T) {
	app := counterAppFullIR()
	dir := setupGeneratedFiles(t, app)

	tasks, err := planner.Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	if err := GenerateTests(app, tasks, dir); err != nil {
		t.Fatalf("generate tests failed: %v", err)
	}

	path := filepath.Join(dir, "test", "counterStore_increments from 0_test.dart")
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read test file: %v", err)
	}

	if !strings.Contains(string(content), "await tester.tap(find.byType(ElevatedButton));") {
		t.Errorf("expected test to tap ElevatedButton, got:\n%s", string(content))
	}
	if !strings.Contains(string(content), "expect(cubit.state.value, 1);") {
		t.Errorf("expected test to assert cubit state value 1, got:\n%s", string(content))
	}
}

func TestGenerateTestsCubitTest(t *testing.T) {
	app := counterAppFullIR()
	// Replace the widget event with a direct store action scenario.
	for i := range app.Behaviors {
		if app.Behaviors[i].ID == "counterStore/increments from 0" {
			app.Behaviors[i].When = "counterStore.increment"
		}
	}

	dir := setupGeneratedFiles(t, app)
	tasks, err := planner.Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	if err := GenerateTests(app, tasks, dir); err != nil {
		t.Fatalf("generate tests failed: %v", err)
	}

	path := filepath.Join(dir, "test", "counterStore_increments from 0_test.dart")
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read test file: %v", err)
	}

	want := []string{
		"import 'package:bloc_test/bloc_test.dart';",
		"blocTest<CounterCubit, CounterState>",
		"act: (cubit) => cubit.increment(),",
		"expect: () => [CounterState(value: 1)],",
	}
	for _, w := range want {
		if !strings.Contains(string(content), w) {
			t.Errorf("expected cubit test to contain %q, got:\n%s", w, string(content))
		}
	}
}
