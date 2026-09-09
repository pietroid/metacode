package behaviorflutter

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
	"github.com/pietroid/metacode/engine/internal/specs/project/rules"
)

// BuildTestCases converts the planned tests and the resolved IR into a slice of
// language-agnostic TestCases.
func BuildTestCases(app *model.App, work plan.Work) ([]TestCase, error) {
	var cases []TestCase
	for _, planned := range work.Tests {
		scenario, ok := app.ScenarioByID(planned.ScenarioID)
		if !ok {
			return nil, fmt.Errorf("scenario %q not found", planned.ScenarioID)
		}
		tc, err := buildTestCase(app, scenario)
		if err != nil {
			return nil, fmt.Errorf("test for %q: %w", planned.ScenarioID, err)
		}
		tc.TargetFile = dart.TestFile(planned.ScenarioID)
		cases = append(cases, tc)
	}
	return cases, nil
}

func buildTestCase(app *model.App, scenario model.BehaviorScenario) (TestCase, error) {
	if len(app.Stores) == 0 {
		return TestCase{}, fmt.Errorf("scenario %q requires at least one store", scenario.ID)
	}

	// One store, checked in the resolve stage: see datarules.CheckSupported.
	store := app.Stores[0]

	tc := TestCase{
		ID:          scenario.ID,
		Description: scenario.Description,
		PackageName: projectrules.PackageName(app.Project.Name),
		CubitClass:  dart.CubitClass(store.Name),
		StateClass:  dart.StateClass(store.Name),
		CubitFile:   dart.LibImport(dart.CubitFile(store.Name)),
		StateFile:   dart.LibImport(dart.StateFile(store.Name)),
	}

	pageName := dart.FirstPageName(app.UI)
	if pageName == "" {
		return TestCase{}, fmt.Errorf("scenario %q requires a page for a widget test", scenario.ID)
	}
	tc.PageWrapperClass = dart.WrapperClass(pageName)
	tc.PageWrapperFile = dart.LibImport(dart.WrapperFile(pageName))

	if err := buildWidgetTestCase(app, scenario, &tc, store); err != nil {
		return TestCase{}, err
	}
	return tc, nil
}

func buildWidgetTestCase(app *model.App, scenario model.BehaviorScenario, tc *TestCase, store model.Store) error {
	if scenario.Given != nil {
		seed, err := seedExpression(scenario.Given, tc.StateClass, store)
		if err != nil {
			return err
		}
		tc.SeedExpression = seed
	}

	if scenario.When != "" {
		action, err := renderAction(scenario.When, app)
		if err != nil {
			return err
		}
		tc.ActionExpression = action
	}

	assertion, err := renderAssertion(scenario.Then, app, store)
	if err != nil {
		return err
	}
	tc.AssertionExpression = assertion
	return nil
}

func seedExpression(given *model.Assertion, stateClass string, store model.Store) (string, error) {
	storeName, field := model.SplitRef(given.Target)
	if _, ok := storeNameMap(storeName, store); !ok {
		return "", nil
	}
	if field == "" {
		return "", nil
	}
	val, err := dartLiteralForValue(given.Value, store)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("cubit.emit(%s(value: %s));", stateClass, val), nil
}

// renderAction turns a scenario's "when" into the statement that drives the
// app under test.
//
// A store action is driven by calling the Cubit, a widget event by interacting
// with the widget. Both land in the same test: the scenario is one behavior of
// one app, so it gets one test, whatever layer its trigger happens to sit in.
func renderAction(when string, app *model.App) (string, error) {
	root, member := model.SplitRef(when)
	if member == "" {
		return "", nil
	}

	if _, ok := app.Symbols.Stores[root]; ok {
		return fmt.Sprintf("cubit.%s();", member), nil
	}

	widgetName, event := root, member
	comp, ok := app.Symbols.Widgets[widgetName]
	if !ok {
		return "", fmt.Errorf("widget %q not found", widgetName)
	}

	switch event {
	case "onPressed":
		return fmt.Sprintf("await tester.tap(%s);", tapTarget(comp)), nil
	default:
		// An error, not an empty action: see docs/decisions.md, "A test with no
		// interaction is not a test".
		return "", fmt.Errorf("no test idiom for event %q on widget %q", event, widgetName)
	}
}

// tapTarget finds the widget to tap by its key rather than by its Flutter type.
// See docs/decisions.md, "Find widgets by key, not by type".
func tapTarget(comp model.UIComponent) string {
	return fmt.Sprintf("find.byKey(const Key(%s))", dart.DartStringLiteral(comp.Name))
}

func renderAssertion(then *model.Assertion, app *model.App, store model.Store) (string, error) {
	if then == nil {
		return "", fmt.Errorf("scenario has no then to assert")
	}

	root, member := model.SplitRef(then.Target)
	if sym, ok := app.Symbols.Lookup(root); ok && sym.Kind == "store" {
		val, err := dartLiteralForAssertion(then, store)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("expect(cubit.state.%s, %s);", member, val), nil
	}

	if sym, ok := app.Symbols.Lookup(root); ok && sym.Kind == "widget" {
		return fmt.Sprintf("expect(find.text(%s), findsOneWidget);", dart.DartStringLiteral(then.Value)), nil
	}

	// A then whose root is neither a store nor a widget cannot be turned into an
	// assertion, and must not fall back to one: see docs/decisions.md, "A test
	// with no interaction is not a test".
	return "", fmt.Errorf("cannot assert on %q: %q is neither a store nor a widget", then.Target, root)
}

func dartLiteralForAssertion(a *model.Assertion, store model.Store) (string, error) {
	if a == nil {
		return "null", nil
	}
	return dartLiteralForValue(a.Value, store)
}

func dartLiteralForValue(raw string, store model.Store) (string, error) {
	dartType := dart.DartTypeFor(store.ValueType)
	v, err := parseLiteral(raw, dartType)
	if err != nil {
		return dart.DartStringLiteral(raw), nil
	}
	return dart.DartLiteral(v, dartType), nil
}

func parseLiteral(raw, dartType string) (any, error) {
	switch dartType {
	case "int":
		v, err := strconv.Atoi(raw)
		if err != nil {
			return nil, err
		}
		return v, nil
	case "num", "double":
		v, err := strconv.ParseFloat(raw, 64)
		if err != nil {
			return nil, err
		}
		return v, nil
	case "bool":
		switch strings.ToLower(raw) {
		case "true":
			return true, nil
		case "false":
			return false, nil
		default:
			return nil, fmt.Errorf("invalid bool")
		}
	default:
		return raw, nil
	}
}

func storeNameMap(name string, store model.Store) (string, bool) {
	if name == store.Name || name == dart.StoreBaseName(store.Name) {
		return store.Name, true
	}
	return "", false
}
