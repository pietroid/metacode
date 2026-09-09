package flutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/plan"
)

func TestGenerateTestsCreatesFiles(t *testing.T) {
	app := counterAppFullIR()
	dir := setupGeneratedFiles(t, app)

	plan, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}
	if err := GenerateTests(app, plan, dir); err != nil {
		t.Fatalf("generate tests failed: %v", err)
	}

	for _, name := range []string{"test/counterStore_increments_from_0_test.dart", "test/counterStore_Show_counter_value_on_the_home_page_test.dart"} {
		path := filepath.Join(dir, name)
		if _, err := os.Stat(path); err != nil {
			t.Errorf("expected %s to exist: %v", name, err)
		}
	}
}

func TestGenerateTestsWidgetTestImports(t *testing.T) {
	app := counterAppFullIR()
	dir := setupGeneratedFiles(t, app)

	plan, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	if err := GenerateTests(app, plan, dir); err != nil {
		t.Fatalf("generate tests failed: %v", err)
	}

	path := filepath.Join(dir, "test", "counterStore_Show_counter_value_on_the_home_page_test.dart")
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

	plan, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	if err := GenerateTests(app, plan, dir); err != nil {
		t.Fatalf("generate tests failed: %v", err)
	}

	path := filepath.Join(dir, "test", "counterStore_Show_counter_value_on_the_home_page_test.dart")
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

	plan, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	if err := GenerateTests(app, plan, dir); err != nil {
		t.Fatalf("generate tests failed: %v", err)
	}

	path := filepath.Join(dir, "test", "counterStore_increments_from_0_test.dart")
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read test file: %v", err)
	}

	// By key, not by type: two buttons on a page make find.byType ambiguous and
	// tap() fails outright.
	if !strings.Contains(string(content), "await tester.tap(find.byKey(const Key('incrementButton')));") {
		t.Errorf("expected test to tap incrementButton by key, got:\n%s", string(content))
	}
	if !strings.Contains(string(content), "expect(cubit.state.value, 1);") {
		t.Errorf("expected test to assert cubit state value 1, got:\n%s", string(content))
	}
}

// TestGenerateTestsStoreActionStaysAWidgetTest covers the 1:1 rule end to end:
// a scenario triggered by a store action is one test against the composed app,
// not a Cubit unit test alongside it.
func TestGenerateTestsStoreActionStaysAWidgetTest(t *testing.T) {
	app := counterAppFullIR()
	// Replace the widget event with a direct store action scenario.
	for i := range app.Behaviors {
		if app.Behaviors[i].ID == "counterStore/increments from 0" {
			app.Behaviors[i].When = "counterStore.increment"
		}
	}

	dir := setupGeneratedFiles(t, app)
	plan, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	if err := GenerateTests(app, plan, dir); err != nil {
		t.Fatalf("generate tests failed: %v", err)
	}

	path := filepath.Join(dir, "test", "counterStore_increments_from_0_test.dart")
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read test file: %v", err)
	}

	want := []string{
		"testWidgets(",
		"home: HomePageWrapper()",
		"cubit.increment();",
		"expect(cubit.state.value, 1);",
	}
	for _, w := range want {
		if !strings.Contains(string(content), w) {
			t.Errorf("expected the test to contain %q, got:\n%s", w, string(content))
		}
	}
	if strings.Contains(string(content), "blocTest") {
		t.Errorf("expected no separate cubit unit test, got:\n%s", string(content))
	}
}
