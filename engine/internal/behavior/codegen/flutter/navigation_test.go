package behaviorflutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/plan"
	"github.com/pietroid/metacode/engine/internal/specs/navigation/codegen/flutter"
)

// A widget event can both write the store and move the app, and that is the
// ordinary case rather than an edge one: two scenarios about one press.
func TestWrapperRunsTheStoreActionAndThePop(t *testing.T) {
	app := sheetApp()
	dir := setupGeneratedFiles(t, app)

	work, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}
	if err := GenerateWrappers(app, work, dir); err != nil {
		t.Fatalf("generate wrappers failed: %v", err)
	}

	code := readFile(t, dir, dart.WrapperFile("saveButton"))
	if !strings.Contains(code, "context.read<CounterCubit>().save()") {
		t.Errorf("expected the save button to run the store action, got:\n%s", code)
	}
	if !strings.Contains(code, "context.pop()") {
		t.Errorf("expected the save button to pop, got:\n%s", code)
	}
	if !strings.Contains(code, "import 'package:go_router/go_router.dart';") {
		t.Errorf("expected the package the call comes from, got:\n%s", code)
	}

	open := readFile(t, dir, dart.WrapperFile("openButton"))
	if !strings.Contains(open, "context.pushNamed('addOne')") {
		t.Errorf("expected the open button to push the route, got:\n%s", open)
	}
}

// A widget with nothing of its own to wire still needs a wrapper when it holds
// one that does, or the wired child is a parameter nothing passes.
func TestAContainerOfWiredChildrenGetsAWrapper(t *testing.T) {
	app := sheetApp()
	work, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}
	found := false
	for _, w := range work.Wrappers {
		if w == "addSheet" {
			found = true
		}
	}
	if !found {
		t.Errorf("expected addSheet to be wrapped, got %v", work.Wrappers)
	}
}

// The router is generated from navigation.yaml alone, and it reaches a route's
// widget through the same wrapper everything else does.
func TestRouterBuildsEachRouteAsItsKind(t *testing.T) {
	app := sheetApp()
	dir := t.TempDir()
	if err := navigationflutter.Generate(app, dir); err != nil {
		t.Fatalf("router generation: %v", err)
	}

	code := readFile(t, dir, dart.RouterFile())
	for _, want := range []string{
		"initialLocation: '/home'",
		"MaterialPage<void>(",
		"ModalBottomSheetPage<void>(",
		"child: const AddSheetWrapper(),",
		"name: 'addOne'",
		"class ModalBottomSheetPage<T> extends Page<T>",
	} {
		if !strings.Contains(code, want) {
			t.Errorf("expected the router to contain %q, got:\n%s", want, code)
		}
	}
	// The dialog page is declared only where a route is one.
	if strings.Contains(code, "class DialogPage") {
		t.Errorf("expected no dialog page in an app with no dialog route")
	}
}

// A project with no routes generates no router, and its app.dart keeps the
// shape it always had.
func TestNoRoutesNoRouter(t *testing.T) {
	dir := t.TempDir()
	if err := navigationflutter.Generate(counterApp(), dir); err != nil {
		t.Fatalf("router generation: %v", err)
	}
	if _, err := os.Stat(filepath.Join(dir, filepath.FromSlash(dart.RouterFile()))); !os.IsNotExist(err) {
		t.Errorf("expected no router file, got %v", err)
	}
}

// An action is verified rather than expected, and the count is one: a test
// that passed on a double push would hide the most common navigation bug.
func TestActionAssertionsAreVerifiedExactlyOnce(t *testing.T) {
	app := sheetApp()
	work, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}
	cases, err := BuildTestCases(app, work)
	if err != nil {
		t.Fatalf("build test cases: %v", err)
	}

	byID := make(map[string]TestCase, len(cases))
	for _, tc := range cases {
		byID[tc.ID] = tc
	}

	push := byID["opening the sheet"]
	if want := "expect(navigation.pushed.where((route) => route == 'addOne').length, 1);"; push.AssertionExpression != want {
		t.Errorf("expected %q, got %q", want, push.AssertionExpression)
	}
	if !push.Settle {
		t.Errorf("expected a push to wait for the transition")
	}

	pop := byID["saving closes the sheet"]
	if want := "expect(navigation.popped.length, 1);"; pop.AssertionExpression != want {
		t.Errorf("expected %q, got %q", want, pop.AssertionExpression)
	}
	if pop.GivenRoute != "addOne" {
		t.Errorf("expected the scenario to start on addOne, got %q", pop.GivenRoute)
	}
	if !pop.UsesRouter {
		t.Errorf("expected a routed app to be driven through its router")
	}
}

// Every test of a routed app hands the router a recorder, so the file that
// declares it is written once for the whole suite.
func TestRoutedTestsShareOneRecorder(t *testing.T) {
	app := sheetApp()
	dir := t.TempDir()
	work, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}
	if err := GenerateTests(app, work, dir); err != nil {
		t.Fatalf("generate tests: %v", err)
	}

	spy := readFile(t, dir, dart.NavigationSpyFile())
	if !strings.Contains(spy, "class NavigationSpy extends NavigatorObserver") {
		t.Errorf("expected the recorder to be a NavigatorObserver, got:\n%s", spy)
	}

	test := readFile(t, dir, dart.TestFile("saving closes the sheet"))
	for _, want := range []string{
		"import 'support/navigation_spy.dart';",
		"final router = buildRouter(observers: [navigation]);",
		"router.pushNamed('addOne');",
		"navigation.clear();",
	} {
		if !strings.Contains(test, want) {
			t.Errorf("expected the test to contain %q, got:\n%s", want, test)
		}
	}
}
