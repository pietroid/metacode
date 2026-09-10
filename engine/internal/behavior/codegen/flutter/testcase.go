// Package tests defines the internal representation for generated behavior tests
// and the logic to build that representation from the resolved IR.
package behaviorflutter

// TestCase is the language-agnostic representation of a single behavior test.
//
// One scenario produces exactly one TestCase, and that test runs against the
// whole app: it pumps the composed page and drives it the way a user would.
// Tests are never split by layer. See AGENTS.md, "One scenario, one test,
// against the whole app".
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

	// Navigation context. A routed app is pumped through its router rather
	// than through one page, and every test passes the router a recorder, so
	// a scenario that verifies a push has something to read it off.
	UsesRouter bool
	RouterFile string // relative import path, e.g. "navigation/router.dart"
	SpyFile    string // relative to test/, e.g. "support/navigation_spy.dart"
	SpyClass   string
	SpyVar     string
	// GivenRoute is the route the test drives to before the scenario starts.
	// It is empty when the scenario starts where the app opens.
	GivenRoute string

	// Settle says the action this scenario fires starts a transition, so the
	// test waits for it rather than pumping one frame. A route animates; a
	// button that only writes a store does not.
	Settle bool

	// Imports the assertion needs on top of the standard ones, relative to lib/.
	Imports []string

	// Output location relative to the project root.
	TargetFile string

	// Test body fragments. These are target-language expressions produced by the
	// builder so the Dart codegen can render them directly.
	SeedState           string // the "Given" state to start from; empty if none
	ActionExpression    string // empty if the scenario has no action
	AssertionExpression string
}
