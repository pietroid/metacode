// Package tests defines the internal representation for generated behavior tests
// and the logic to build that representation from the resolved IR.
package behaviorflutter

// TestCase is the language-agnostic representation of a single behavior test.
//
// One scenario produces exactly one TestCase, and that test runs against the
// whole app: it pumps the composed page and drives it the way a user would.
// Tests are never split by layer. See docs/decisions.md, "One scenario, one
// test, against the whole app".
type TestCase struct {
	ID          string
	Description string

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
