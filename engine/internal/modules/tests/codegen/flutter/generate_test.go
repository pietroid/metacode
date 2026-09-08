package flutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/modules/tests"
)

// TestGenerateWritesOneFilePerCase covers the 1:1 rule at the codegen edge:
// every case renders through the same widget-test template, including one whose
// action drives a Cubit directly. There is no second template to pick.
func TestGenerateWritesOneFilePerCase(t *testing.T) {
	dir := t.TempDir()
	cases := []tests.TestCase{
		{
			ID:                  "counterStore/increments from 0",
			Description:         "increment changes state",
			PackageName:         "counter_app",
			CubitClass:          "CounterCubit",
			StateClass:          "CounterState",
			CubitFile:           "stores/counter_cubit.dart",
			StateFile:           "stores/counter_state.dart",
			PageWrapperClass:    "HomePageWrapper",
			PageWrapperFile:     "wrappers/home_page_wrapper.dart",
			TargetFile:          "test/counter_store_increments_from_0_test.dart",
			ActionExpression:    "cubit.increment();",
			AssertionExpression: "expect(cubit.state.value, 1);",
		},
		{
			ID:                  "counterStore/Show counter value on the home page",
			Description:         "show counter value",
			PackageName:         "counter_app",
			CubitClass:          "CounterCubit",
			StateClass:          "CounterState",
			CubitFile:           "stores/counter_cubit.dart",
			StateFile:           "stores/counter_state.dart",
			PageWrapperClass:    "HomePageWrapper",
			PageWrapperFile:     "wrappers/home_page_wrapper.dart",
			TargetFile:          "test/counter_store_show_counter_value_test.dart",
			SeedExpression:      "cubit.emit(CounterState(value: 5));",
			ActionExpression:    "",
			AssertionExpression: "expect(find.text('5'), findsOneWidget);",
		},
	}

	if err := Generate(cases, dir); err != nil {
		t.Fatalf("generate failed: %v", err)
	}

	for _, name := range []string{"test/counter_store_increments_from_0_test.dart", "test/counter_store_show_counter_value_test.dart"} {
		path := filepath.Join(dir, name)
		if _, err := os.Stat(path); err != nil {
			t.Errorf("expected %s to exist: %v", name, err)
		}
	}

	actionPath := filepath.Join(dir, "test", "counter_store_increments_from_0_test.dart")
	actionContent, err := os.ReadFile(actionPath)
	if err != nil {
		t.Fatalf("read store-action test: %v", err)
	}
	wantAction := []string{
		"testWidgets(",
		"home: HomePageWrapper()",
		"cubit.increment();",
		"expect(cubit.state.value, 1);",
	}
	for _, w := range wantAction {
		if !strings.Contains(string(actionContent), w) {
			t.Errorf("expected store-action test to contain %q, got:\n%s", w, string(actionContent))
		}
	}
	if strings.Contains(string(actionContent), "bloc_test") {
		t.Errorf("expected no bloc_test unit test, got:\n%s", string(actionContent))
	}

	widgetPath := filepath.Join(dir, "test", "counter_store_show_counter_value_test.dart")
	widgetContent, err := os.ReadFile(widgetPath)
	if err != nil {
		t.Fatalf("read widget test: %v", err)
	}
	wantWidget := []string{
		"import 'package:flutter/material.dart';",
		"import 'package:flutter_bloc/flutter_bloc.dart';",
		"import 'package:counter_app/wrappers/home_page_wrapper.dart';",
		"cubit.emit(CounterState(value: 5));",
		"expect(find.text('5'), findsOneWidget);",
	}
	for _, w := range wantWidget {
		if !strings.Contains(string(widgetContent), w) {
			t.Errorf("expected widget test to contain %q, got:\n%s", w, string(widgetContent))
		}
	}
}

func TestGenerateOmitsEmptyActionAndSeed(t *testing.T) {
	dir := t.TempDir()
	cases := []tests.TestCase{
		{
			ID:                  "s1",
			Description:         "render only",
			PackageName:         "counter_app",
			CubitClass:          "CounterCubit",
			StateClass:          "CounterState",
			CubitFile:           "stores/counter_cubit.dart",
			StateFile:           "stores/counter_state.dart",
			PageWrapperClass:    "HomePageWrapper",
			PageWrapperFile:     "wrappers/home_page_wrapper.dart",
			TargetFile:          "test/render_test.dart",
			SeedExpression:      "",
			ActionExpression:    "",
			AssertionExpression: "expect(find.text('5'), findsOneWidget);",
		},
	}

	if err := Generate(cases, dir); err != nil {
		t.Fatalf("generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(dir, "test", "render_test.dart"))
	if err != nil {
		t.Fatalf("read test: %v", err)
	}

	if strings.Contains(string(content), "await tester.pump();") {
		t.Errorf("expected no pump when action is empty")
	}
	if strings.Contains(string(content), "cubit.emit") {
		t.Errorf("expected no seed when seed is empty")
	}
}
