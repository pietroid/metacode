package behaviorflutter

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
	"github.com/pietroid/metacode/engine/internal/order"
	"github.com/pietroid/metacode/engine/internal/specs/project/rules"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

// BuildTestCases converts the planned tests and the resolved IR into a slice of
// language-agnostic TestCases.
func BuildTestCases(app *model.App, work plan.Work) ([]TestCase, error) {
	var cases []TestCase
	// A scenario that never becomes a file is a scenario that silently stops
	// being checked, and the suite stays green while the app is broken. Two IDs
	// can slug to one file name, and the second write would overwrite the first.
	byFile := make(map[string]string, len(work.Tests))
	for _, scenarioID := range work.Tests {
		scenario, ok := app.ScenarioByID(scenarioID)
		if !ok {
			return nil, fmt.Errorf("scenario %q not found", scenarioID)
		}
		tc, err := buildTestCase(app, scenario)
		if err != nil {
			return nil, fmt.Errorf("test for %q: %w", scenarioID, err)
		}
		tc.TargetFile = dart.TestFile(scenarioID)
		if other, clash := byFile[tc.TargetFile]; clash {
			return nil, fmt.Errorf("scenarios %q and %q both write %s: rename one so both are tested", other, scenarioID, tc.TargetFile)
		}
		byFile[tc.TargetFile] = scenarioID
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
		seed, err := seedState(scenario.Given, tc.StateClass, store)
		if err != nil {
			return err
		}
		tc.SeedState = seed
		if m, ok := app.ElementModel(store.ValueType); ok && seed != "" {
			tc.Imports = append(tc.Imports, fmt.Sprintf("models/%s.dart", dart.SnakeCase(m.Name)))
		}
	}

	if scenario.When != "" {
		action, err := renderAction(scenario, app)
		if err != nil {
			return err
		}
		tc.ActionExpression = action
	}

	assertion, imports, err := renderAssertion(scenario, app, store)
	if err != nil {
		return err
	}
	tc.AssertionExpression = assertion
	tc.Imports = append(tc.Imports, imports...)
	return nil
}

// seedState renders the state a scenario's "Given" starts from. It is passed
// to the store's seeded constructor rather than emitted into a built store,
// which is what a store's own state is for.
func seedState(given *model.Assertion, stateClass string, store model.Store) (string, error) {
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
	return fmt.Sprintf("%s(value: %s)", stateClass, val), nil
}

// renderAction turns a scenario's "when" into the statement that drives the
// app under test.
//
// A store action is driven by calling the Cubit, a widget event by interacting
// with the widget. Both land in the same test: the scenario is one behavior of
// one app, so it gets one test, whatever layer its trigger happens to sit in.
func renderAction(scenario model.BehaviorScenario, app *model.App) (string, error) {
	ref := model.ParseRef(scenario.When)
	event := ref.Last()
	if event == "" {
		return "", nil
	}

	if _, ok := app.Symbols.Stores[ref.Root]; ok {
		return fmt.Sprintf("cubit.%s();", event), nil
	}

	// What the widget does when it is tapped is decided by the prop, not by
	// the name the spec addressed it with: an alias reads however the spec
	// author found clearest, and only `onChanged` says this is a checkbox.
	if resolved, ok := app.Symbols.Events[scenario.When]; ok {
		event = resolved.Event
	}

	if _, ok := app.Symbols.Widgets[ref.Root]; !ok {
		return "", fmt.Errorf("widget %q not found", ref.Root)
	}

	// A test taps what fires the event. That is the widget itself when the
	// event is on its root, and the widget the alias named when it is not: a
	// row holding two buttons cannot be tapped in the middle and mean one.
	key := ref.Root
	if resolved, ok := app.Symbols.Events[scenario.When]; ok && !resolved.OnRoot {
		key = resolved.Address
	}

	finder, err := widgetFinder(ref, scenario, key)
	if err != nil {
		return "", err
	}

	switch event {
	case "onPressed", "onTap", "onChanged":
		// Tapping is how a user reaches all three. A checkbox toggles, a tile
		// fires onTap, a button fires onPressed.
		return fmt.Sprintf("await tester.tap(%s);", finder), nil
	default:
		// An error, not an empty action: see AGENTS.md, "A test with no
		// interaction is not a test".
		return "", fmt.Errorf("no test idiom for event %q on widget %q", event, ref.Root)
	}
}

// widgetFinder finds a widget by its key. A ref naming a row finds that row's
// key, which carries the index the widget was built with.
// See AGENTS.md, "Find widgets by key, not by type".
func widgetFinder(ref model.Ref, scenario model.BehaviorScenario, key string) (string, error) {
	if row, ok := ref.RowSelector(); ok {
		index, err := rowIndex(row, scenario)
		if err != nil {
			return "", err
		}
		key = fmt.Sprintf("%s_%d", key, index)
	}
	return fmt.Sprintf("find.byKey(const Key(%s))", dart.DartStringLiteral(key)), nil
}

// rowIndex turns a row selector into the index the row was built with. `last`
// is only knowable because the scenario said what the list holds: the given
// seeds it, so its length is the number of rows on screen.
func rowIndex(row string, scenario model.BehaviorScenario) (int, error) {
	if row == model.RowFirst {
		return 0, nil
	}
	if scenario.Given == nil {
		return 0, fmt.Errorf("`last` needs a given saying what the list holds")
	}
	var list []any
	if err := json.Unmarshal([]byte(scenario.Given.Value), &list); err != nil {
		return 0, fmt.Errorf("`last` needs a given holding a list, got %q", scenario.Given.Value)
	}
	if len(list) == 0 {
		return 0, fmt.Errorf("`last` of an empty list has no row")
	}
	return len(list) - 1, nil
}

// renderAssertion turns a scenario's then into the expectation, and reports any
// widget file the expectation has to import.
func renderAssertion(scenario model.BehaviorScenario, app *model.App, store model.Store) (string, []string, error) {
	then := scenario.Then
	if then == nil {
		return "", nil, fmt.Errorf("scenario has no then to assert")
	}

	ref := model.ParseRef(then.Target)
	if sym, ok := app.Symbols.Lookup(ref.Root); ok && sym.Kind == "store" {
		expr, err := storeExpression(ref, app, store)
		if err != nil {
			return "", nil, err
		}
		val, err := assertedLiteral(ref, then, store)
		if err != nil {
			return "", nil, err
		}
		return fmt.Sprintf("expect(%s, %s);", expr, val), nil, nil
	}

	if sym, ok := app.Symbols.Lookup(ref.Root); ok && sym.Kind == "widget" {
		return widgetAssertion(ref, scenario, app)
	}

	// A then whose root is neither a store nor a widget cannot be turned into an
	// assertion, and must not fall back to one: see AGENTS.md, "A test with
	// no interaction is not a test".
	return "", nil, fmt.Errorf("cannot assert on %q: %q is neither a store nor a widget", then.Target, ref.Root)
}

// storeExpression walks a ref into the Dart that reads it off the state. A
// member after a row selector is a field of one element, and an element is a
// map until models.yaml is read, so it is looked up rather than dotted.
func storeExpression(ref model.Ref, app *model.App, store model.Store) (string, error) {
	_, isModel := app.ElementModel(store.ValueType)
	expr := "cubit.state"
	afterRow := false
	for _, m := range ref.Members {
		switch {
		case model.IsRowSelector(m):
			expr += "." + m
			afterRow = true
		case afterRow && !isModel:
			expr += fmt.Sprintf("[%s]", dart.DartStringLiteral(m))
		default:
			expr += "." + m
		}
	}
	return expr, nil
}

// assertedLiteral is the value the expectation compares against. It is typed by
// the store only when the ref reads the store's whole value; a length is a
// number, and a field of an element is whatever it looks like, because no model
// declares its type yet.
func assertedLiteral(ref model.Ref, then *model.Assertion, store model.Store) (string, error) {
	if len(ref.Members) == 1 && ref.Members[0] != model.LengthMember {
		return dartLiteralForValue(then.Value, store)
	}
	return dart.RawLiteral(then.Value), nil
}

func widgetAssertion(ref model.Ref, scenario model.BehaviorScenario, app *model.App) (string, []string, error) {
	then := scenario.Then

	// A then whose value names another widget asserts that widget is on screen,
	// and is found by key like every other widget a test looks for.
	if val, ok := app.Symbols.Lookup(then.Value); ok && val.Kind == "widget" {
		return fmt.Sprintf("expect(find.byKey(const Key(%s)), findsOneWidget);", dart.DartStringLiteral(then.Value)), nil, nil
	}

	if ref.Last() == model.CountMember {
		// How many rows there are is the one question a key cannot answer, so
		// this is the one assertion that finds by type.
		count, err := strconv.Atoi(then.Value)
		if err != nil {
			return "", nil, fmt.Errorf("%s must be a number, got %q", then.Target, then.Value)
		}
		class := dart.WidgetClass(ref.Root)
		imports := []string{dart.LibImport(dart.WidgetFile(ref.Root))}
		return fmt.Sprintf("expect(find.byType(%s), findsNWidgets(%d));", class, count), imports, nil
	}

	finder, err := widgetFinder(ref, scenario, ref.Root)
	if err != nil {
		return "", nil, err
	}

	variable := ref.Last()
	comp, ok := app.Symbols.Widgets[ref.Root]
	if !ok {
		return "", nil, fmt.Errorf("widget %q not found", ref.Root)
	}
	kind, prop, ok := propShowing(comp.Kind, comp, variable)
	if !ok {
		return "", nil, fmt.Errorf("widget %q does not render %q", ref.Root, variable)
	}

	c := catalog.Default()
	propType := c.PropType(kind, prop)
	if propType.IsWidget() || propType == catalog.TypeText {
		// A variable under a widget prop is rendered as text, so text is what
		// the assertion looks for. A row looks inside itself, so the same
		// variable on a sibling row cannot satisfy it.
		if _, isRow := ref.RowSelector(); !isRow {
			return fmt.Sprintf("expect(find.text(%s), findsOneWidget);", dart.DartStringLiteral(then.Value)), nil, nil
		}
		return fmt.Sprintf("expect(find.descendant(of: %s, matching: find.text(%s)), findsOneWidget);",
			finder, dart.DartStringLiteral(then.Value)), nil, nil
	}

	sym, _ := c.Find(kind)
	return fmt.Sprintf("expect(tester.widget<%s>(%s).%s, %s);",
		sym.FlutterWidget, finder, prop, dart.RawLiteral(then.Value)), nil, nil
}

// propShowing finds the widget kind and the prop that carry a variable, which
// together say how to read it back: a title is text on screen, a checkbox value
// is a field of the rendered widget. It walks the raw props the same way the UI
// rules do, because a variable can sit any number of mappings deep.
func propShowing(kind string, comp model.UIComponent, variable string) (string, string, bool) {
	for _, prop := range order.Keys(comp.Props) {
		if k, p, ok := propShowingIn(kind, prop, comp.Props[prop], variable); ok {
			return k, p, true
		}
	}
	for _, child := range comp.Children {
		if k, p, ok := propShowing(child.Kind, child, variable); ok {
			return k, p, true
		}
	}
	return "", "", false
}

func propShowingIn(kind, prop string, raw any, variable string) (string, string, bool) {
	switch v := raw.(type) {
	case string:
		if v == variable {
			return kind, prop, true
		}
	case []any:
		for _, item := range v {
			if k, p, ok := propShowingIn(kind, prop, item, variable); ok {
				return k, p, true
			}
		}
	case map[string]any:
		for _, key := range order.Keys(v) {
			nextKind, nextProp := kind, key
			if catalog.Default().IsKnown(key) {
				nextKind, nextProp = key, defaultPropOf(key)
			}
			if k, p, ok := propShowingIn(nextKind, nextProp, v[key], variable); ok {
				return k, p, true
			}
		}
	}
	return "", "", false
}

func defaultPropOf(kind string) string {
	if sym, ok := catalog.Default().Find(kind); ok {
		return sym.DefaultProp
	}
	return ""
}

// dartLiteralForValue turns the value an assertion carries into a Dart literal
// of the store's type. A value the store's type cannot hold is an error: it
// used to fall back to a Dart string literal, which seeded `'[]'` into a list
// store and produced a test that ran, passed nothing meaningful, and reported
// the scenario as covered.
func dartLiteralForValue(raw string, store model.Store) (string, error) {
	dartType := dart.DartTypeFor(store.ValueType)
	v, err := parseLiteral(raw, dartType)
	if err != nil {
		return "", fmt.Errorf("value %q is not a %s, which is what %s holds: %w", raw, store.ValueType, store.Name, err)
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
		if strings.HasPrefix(dartType, "List<") {
			var list []any
			if err := json.Unmarshal([]byte(raw), &list); err != nil {
				return nil, fmt.Errorf("invalid list: %w", err)
			}
			return list, nil
		}
		return raw, nil
	}
}

func storeNameMap(name string, store model.Store) (string, bool) {
	if name == store.Name || name == dart.StoreBaseName(store.Name) {
		return store.Name, true
	}
	return "", false
}
