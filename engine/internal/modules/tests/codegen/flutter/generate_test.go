package flutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/modules/tests"
)

func TestGenerateWritesCubitAndWidgetTests(t *testing.T) {
	dir := t.TempDir()
	cases := []tests.TestCase{
		{
			ID:                  "counterStore/increments from 0",
			Description:         "increment changes state",
			Type:                tests.TestTypeCubit,
			PackageName:         "counter_app",
			CubitClass:          "CounterCubit",
			StateClass:          "CounterState",
			CubitFile:           "stores/counter_cubit.dart",
			StateFile:           "stores/counter_state.dart",
			TargetFile:          "test/counter_store_increments_from_0_test.dart",
			ActionExpression:    "act: (cubit) => cubit.increment(),",
			AssertionExpression: "expect: () => [CounterState(value: 1)],",
		},
		{
			ID:                  "counterStore/Show counter value on the home page",
			Description:         "show counter value",
			Type:                tests.TestTypeWidget,
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

	cubitPath := filepath.Join(dir, "test", "counter_store_increments_from_0_test.dart")
	cubitContent, err := os.ReadFile(cubitPath)
	if err != nil {
		t.Fatalf("read cubit test: %v", err)
	}
	wantCubit := []string{
		"import 'package:bloc_test/bloc_test.dart';",
		"blocTest<CounterCubit, CounterState>(",
		"act: (cubit) => cubit.increment(),",
		"expect: () => [CounterState(value: 1)],",
	}
	for _, w := range wantCubit {
		if !strings.Contains(string(cubitContent), w) {
			t.Errorf("expected cubit test to contain %q, got:\n%s", w, string(cubitContent))
		}
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
			Type:                tests.TestTypeWidget,
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
