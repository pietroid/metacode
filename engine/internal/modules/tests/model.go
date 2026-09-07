// Package tests defines the internal representation for generated behavior tests
// and the logic to build that representation from the resolved IR.
package tests

// TestType classifies a generated test.
type TestType string

const (
	// TestTypeCubit is a unit test for a store Cubit using bloc_test.
	TestTypeCubit TestType = "cubit"
	// TestTypeWidget is a widget test using WidgetTester.
	TestTypeWidget TestType = "widget"
)

// TestCase is the language-agnostic representation of a single behavior test.
// Target-language code generators consume a slice of TestCases and render the
// appropriate test files.
type TestCase struct {
	ID          string
	Description string
	Type        TestType

	// Project context.
	PackageName string

	// Store context.
	CubitClass string
	StateClass string
	CubitFile  string // relative import path, e.g. "stores/counter_cubit.dart"
	StateFile  string // relative import path, e.g. "stores/counter_state.dart"

	// Widget context (used by widget tests).
	PageWrapperClass string
	PageWrapperFile  string // relative import path, e.g. "wrappers/home_page_wrapper.dart"

	// Output location relative to the project root.
	TargetFile string

	// Test body fragments. These are target-language expressions produced by the
	// builder so the Dart codegen can render them directly.
	SeedExpression      string // empty if no setup is needed
	ActionExpression    string // empty if the scenario has no action
	AssertionExpression string
}
