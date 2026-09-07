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

	if isCubitTest(app, scenario) {
		tc.Type = TestTypeCubit
		if err := buildCubitTestCase(app, scenario, &tc, store); err != nil {
			return TestCase{}, err
		}
		return tc, nil
	}

	tc.Type = TestTypeWidget
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

func buildCubitTestCase(app *ir.IR, scenario ir.BehaviorScenario, tc *TestCase, store ir.Store) error {
	_, action := data.SplitDot(scenario.When)
	expectedValue, err := dartLiteralForAssertion(scenario.Then, store)
	if err != nil {
		return err
	}
	tc.ActionExpression = fmt.Sprintf("act: (cubit) => cubit.%s(),", action)
	tc.AssertionExpression = fmt.Sprintf("expect: () => [%s(value: %s)],", tc.StateClass, expectedValue)
	return nil
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

func isCubitTest(app *ir.IR, scenario ir.BehaviorScenario) bool {
	if scenario.When == "" {
		return false
	}
	store, action := data.SplitDot(scenario.When)
	if action == "" {
		return false
	}
	if _, ok := app.Symbols.Stores[store]; ok {
		return true
	}
	return false
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

func renderAction(when string, app *ir.IR) (string, error) {
	widgetName, event := data.SplitDot(when)
	if event == "" {
		return "", nil
	}
	comp, ok := app.Symbols.Widgets[widgetName]
	if !ok {
		return "", fmt.Errorf("widget %q not found", widgetName)
	}

	switch event {
	case "onPressed":
		tapTarget := findTapTarget(comp)
		return fmt.Sprintf("await tester.tap(%s);", tapTarget), nil
	default:
		return "", nil
	}
}

func findTapTarget(comp ir.UIComponent) string {
	widgetClass := flutterWidgetClass(comp.Kind)
	if widgetClass != "" {
		return fmt.Sprintf("find.byType(%s)", widgetClass)
	}
	return "find.byType(ElevatedButton)"
}

func flutterWidgetClass(kind string) string {
	switch kind {
	case "floatingActionButton":
		return "FloatingActionButton"
	case "elevatedButton":
		return "ElevatedButton"
	case "textButton":
		return "TextButton"
	case "iconButton":
		return "IconButton"
	default:
		return ""
	}
}

func renderAssertion(then *ir.Assertion, app *ir.IR, store ir.Store) (string, error) {
	if then == nil {
		return "expect(find.byType(Container), findsOneWidget);", nil
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

	return fmt.Sprintf("expect(cubit.state.value, %s);", then.Value), nil
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
