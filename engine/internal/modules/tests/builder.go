package tests

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/data"
	"github.com/pietroid/metacode/engine/internal/modules/project"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
	"github.com/pietroid/metacode/engine/internal/planner"
)

// BuildTestCases converts planner tasks and the resolved IR into a slice of
// language-agnostic TestCases.
func BuildTestCases(app *ir.IR, tasks []planner.Task) ([]TestCase, error) {
	var cases []TestCase
	for _, task := range tasks {
		if task.Type != planner.TaskTest {
			continue
		}
		scenario, err := findScenario(app, task.ScenarioID)
		if err != nil {
			return nil, fmt.Errorf("test %s: %w", task.ID, err)
		}
		tc, err := buildTestCase(app, scenario)
		if err != nil {
			return nil, fmt.Errorf("test %s: %w", task.ID, err)
		}
		tc.TargetFile = task.TargetFile
		cases = append(cases, tc)
	}
	return cases, nil
}

func buildTestCase(app *ir.IR, scenario ir.BehaviorScenario) (TestCase, error) {
	if len(app.Stores) == 0 {
		return TestCase{}, fmt.Errorf("scenario %q requires at least one store", scenario.ID)
	}

	store := app.Stores[0]
	base := shared.StoreBaseName(store.Name)
	packageName := project.PackageName(app.Project.Name)

	tc := TestCase{
		ID:          scenario.ID,
		Description: scenario.Description,
		PackageName: packageName,
		CubitClass:  shared.PascalCase(base) + "Cubit",
		StateClass:  shared.PascalCase(base) + "State",
		CubitFile:   fmt.Sprintf("stores/%s_cubit.dart", shared.SnakeCase(base)),
		StateFile:   fmt.Sprintf("stores/%s_state.dart", shared.SnakeCase(base)),
	}

	pageName := shared.FirstPageName(app.UI)
	if pageName == "" {
		return TestCase{}, fmt.Errorf("scenario %q requires a page for a widget test", scenario.ID)
	}
	tc.PageWrapperClass = shared.PascalCase(pageName) + "Wrapper"
	tc.PageWrapperFile = fmt.Sprintf("wrappers/%s_wrapper.dart", shared.SnakeCase(pageName))

	if err := buildWidgetTestCase(app, scenario, &tc, store); err != nil {
		return TestCase{}, err
	}
	return tc, nil
}

func buildWidgetTestCase(app *ir.IR, scenario ir.BehaviorScenario, tc *TestCase, store ir.Store) error {
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

func seedExpression(given *ir.Assertion, stateClass string, store ir.Store) (string, error) {
	storeName, field := data.SplitDot(given.Target)
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
func renderAction(when string, app *ir.IR) (string, error) {
	root, member := data.SplitDot(when)
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
		// An event with no known tester idiom used to return an empty action,
		// which produced a test that pumped the widget and asserted without
		// ever interacting. It passed whenever the initial state happened to
		// match, and reported the scenario as covered.
		return "", fmt.Errorf("no test idiom for event %q on widget %q", event, widgetName)
	}
}

// tapTarget finds the widget to tap by its key rather than by its Flutter type.
// The generated dumb widget carries key: Key("<name>"), and finding by type
// fails the moment a page has two buttons: tap() reports "ambiguously found
// multiple matching widgets" and every tap scenario in the spec fails at once.
func tapTarget(comp ir.UIComponent) string {
	return fmt.Sprintf("find.byKey(const Key(%s))", shared.DartStringLiteral(comp.Name))
}

func renderAssertion(then *ir.Assertion, app *ir.IR, store ir.Store) (string, error) {
	if then == nil {
		return "", fmt.Errorf("scenario has no then to assert")
	}

	root, member := data.SplitDot(then.Target)
	if sym, ok := app.Symbols.Lookup(root); ok && sym.Kind == "store" {
		val, err := dartLiteralForAssertion(then, store)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("expect(cubit.state.%s, %s);", member, val), nil
	}

	if sym, ok := app.Symbols.Lookup(root); ok && sym.Kind == "widget" {
		return fmt.Sprintf("expect(find.text(%s), findsOneWidget);", shared.DartStringLiteral(then.Value)), nil
	}

	// A then whose root is neither a store nor a widget cannot be turned into an
	// assertion. Falling back to the store's value, as this used to, wrote a
	// test that asserted something the scenario never mentioned.
	return "", fmt.Errorf("cannot assert on %q: %q is neither a store nor a widget", then.Target, root)
}

func dartLiteralForAssertion(a *ir.Assertion, store ir.Store) (string, error) {
	if a == nil {
		return "null", nil
	}
	return dartLiteralForValue(a.Value, store)
}

func dartLiteralForValue(raw string, store ir.Store) (string, error) {
	dartType := data.DartTypeFor(store.ValueType)
	v, err := parseLiteral(raw, dartType)
	if err != nil {
		return shared.DartStringLiteral(raw), nil
	}
	return data.DartLiteral(v, dartType), nil
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

func storeNameMap(name string, store ir.Store) (string, bool) {
	if name == store.Name || name == shared.StoreBaseName(store.Name) {
		return store.Name, true
	}
	return "", false
}

func findScenario(app *ir.IR, id string) (ir.BehaviorScenario, error) {
	for _, s := range app.Behaviors {
		if s.ID == id {
			return s, nil
		}
	}
	return ir.BehaviorScenario{}, fmt.Errorf("scenario %q not found", id)
}
