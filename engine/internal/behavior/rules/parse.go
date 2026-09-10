// Package behaviorrules interprets the behavior spec: it parses scenarios and
// their given/when/then assertions, and resolves which store action a widget
// event runs.
//
// Behaviors are the centerpiece spec — they are what the tests verify and what
// the implement stage is asked to satisfy — which is why they sit at the top
// level rather than beside the other spec kinds.
package behaviorrules

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/order"
)

// op is the assertion operator. A `given` writes it as the YAML colon, a
// `then` spells it out and follows it with the predicate: `be` for a value the
// app settled on, or the name of an action its subject performed.
const op = "should"

// ParseGiven reads a `given` block, which is a mapping of one target to the
// value it holds:
//
//	given:
//	  counterStore.value: 0
//
// The colon is the operator, so the value stays YAML — a list or a mapping
// needs no quoting and no second parser.
// It also reads where the app starts, which is the one other precondition a
// scenario can set:
//
//	given:
//	  navigator.route: addTask
//	  draftStore.value: "Buy milk"
//
// Where the app is and what it holds are two different kinds of fact, so they
// are two fields rather than two entries in one list, and the value half is
// still one target.
func ParseGiven(raw any) (*model.Assertion, string, error) {
	if raw == nil {
		return nil, "", nil
	}
	m, ok := raw.(map[string]any)
	if !ok {
		return nil, "", fmt.Errorf("given must be a mapping of a target to its value, as in `given:` then `counterStore.value: 0`; got %T", raw)
	}

	route := ""
	if v, ok := m[model.GivenRouteTarget]; ok {
		name, ok := v.(string)
		if !ok || name == "" {
			return nil, "", fmt.Errorf("`%s` must name a route from navigation.yaml", model.GivenRouteTarget)
		}
		route = name
	}

	values := make(map[string]any, len(m))
	for k, v := range m {
		if k != model.GivenRouteTarget {
			values[k] = v
		}
	}
	if len(values) == 0 {
		return nil, route, nil
	}
	if len(values) > 1 {
		return nil, "", fmt.Errorf("given names %d values, expected one", len(values))
	}
	target := order.Keys(values)[0]
	// A precondition is state, so its verb is never anything else.
	return &model.Assertion{Target: target, Verb: model.VerbBe, Value: formatValue(values[target])}, route, nil
}

// formatValue renders a YAML value as the string an Assertion carries. Scalars
// keep their plain spelling; a list or a mapping is rendered as JSON, which is
// YAML flow syntax and so reads back the same way it was written.
func formatValue(v any) string {
	switch val := v.(type) {
	case nil:
		return ""
	case string:
		return val
	case bool:
		return strconv.FormatBool(val)
	case int:
		return strconv.Itoa(val)
	case float64:
		return strconv.FormatFloat(val, 'f', -1, 64)
	}
	out, err := json.Marshal(v)
	if err != nil {
		return fmt.Sprintf("%v", v)
	}
	return string(out)
}

// ParseAssertion parses a `then` string into a model.Assertion.
//
// The sentence is "<target> should <verb> <value>", and the first word after
// the operator is the verb. `be` is the state predicate and everything else is
// an action, which is what lets `navigator should pop` carry no value at all
// while `counterStore.value should be 6` reads exactly as it always did.
//
// The whitespace around the operator is required, so that a value containing
// the word is not split incorrectly.
func ParseAssertion(s string) (*model.Assertion, bool, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, false, nil
	}

	idx := strings.Index(s, " "+op+" ")
	if idx == -1 {
		return nil, true, fmt.Errorf("malformed assertion %q (expected \"<target> should be <value>\" or \"<target> should <action>\")", s)
	}

	target := strings.TrimSpace(s[:idx])
	if target == "" {
		return nil, true, fmt.Errorf("assertion has empty target: %q", s)
	}

	verb, value := splitVerb(strings.TrimSpace(s[idx+len(op)+2:]))
	if verb == "" {
		return nil, true, fmt.Errorf("assertion %q says what should happen to %q but not what: expected a value after `should be`, or an action after `should`", s, target)
	}
	return &model.Assertion{Target: target, Verb: verb, Value: unquote(value)}, true, nil
}

// splitVerb takes the first word of what follows the operator as the verb, and
// leaves the rest as the value. `be 6` is the verb `be` and the value `6`; a
// verb with no argument leaves an empty value.
func splitVerb(rest string) (string, string) {
	verb, value, found := strings.Cut(rest, " ")
	if !found {
		return strings.TrimSpace(verb), ""
	}
	return strings.TrimSpace(verb), strings.TrimSpace(value)
}

// unquote strips the quotes around a written value. A `then` is a sentence, so
// its value carries whatever quoting the author used to mark a string; leaving
// them in put the quotes inside the string and made a test look for `"Buy milk"`
// with the quotes on screen.
func unquote(value string) string {
	if len(value) >= 2 && value[0] == '"' && value[len(value)-1] == '"' {
		return value[1 : len(value)-1]
	}
	return value
}

// ParseBehaviorScenario converts the raw string fields of a behavior scenario
// into the structured model.BehaviorScenario representation.
func ParseBehaviorScenario(id, description string, groupPath []string, givenRaw any, whenRaw, thenRaw string) (model.BehaviorScenario, error) {
	given, route, err := ParseGiven(givenRaw)
	if err != nil {
		return model.BehaviorScenario{}, fmt.Errorf("scenario %q: given: %w", id, err)
	}

	then, hasThen, err := ParseAssertion(thenRaw)
	if err != nil {
		return model.BehaviorScenario{}, fmt.Errorf("scenario %q: then: %w", id, err)
	}
	if !hasThen {
		return model.BehaviorScenario{}, fmt.Errorf("scenario %q: missing then", id)
	}

	return model.BehaviorScenario{
		ID:          id,
		Description: description,
		GroupPath:   groupPath,
		Given:       given,
		GivenRoute:  route,
		When:        strings.TrimSpace(whenRaw),
		Then:        then,
	}, nil
}

// BuildScenarios flattens the behaviors.yaml groups into one scenario per
// leaf, carrying the group path so a reader can still see the nesting.
func BuildScenarios(raw map[string]any) ([]model.BehaviorScenario, error) {
	var scenarios []model.BehaviorScenario
	for _, group := range order.Keys(raw) {
		if err := appendBehaviorScenarios(group, raw[group], nil, &scenarios); err != nil {
			return nil, err
		}
	}
	return scenarios, nil
}

func appendBehaviorScenarios(key string, raw any, path []string, out *[]model.BehaviorScenario) error {
	switch v := raw.(type) {
	case map[string]any:
		if looksLikeScenario(v) {
			id := strings.Join(append(append([]string(nil), path...), key), "/")
			scenario, err := ParseBehaviorScenario(
				id,
				key,
				path,
				v["given"],
				stringValue(v, "when"),
				stringValue(v, "then"),
			)
			if err != nil {
				return err
			}
			*out = append(*out, scenario)
			return nil
		}
		// Copy rather than append in place: sibling recursive calls each append
		// to newPath, and a shared backing array would let them overwrite each
		// other's group path.
		newPath := append(append([]string(nil), path...), key)
		for _, k := range order.Keys(v) {
			if err := appendBehaviorScenarios(k, v[k], newPath, out); err != nil {
				return err
			}
		}
	case []any:
		for _, item := range v {
			if err := appendBehaviorScenarios(key, item, path, out); err != nil {
				return err
			}
		}
	}
	return nil
}

func looksLikeScenario(m map[string]any) bool {
	_, hasWhen := m["when"]
	_, hasThen := m["then"]
	return hasWhen || hasThen
}

func stringValue(m map[string]any, key string) string {
	if v, ok := m[key].(string); ok {
		return v
	}
	return ""
}

// ValidateGivens checks a seeded element against the shape it is supposed to
// have. A key the model does not declare, or a required field the given leaves
// out, is a spec error naming the scenario rather than a Dart compile error in
// a generated file nobody wrote.
func ValidateGivens(app *model.App) []error {
	var errs []error
	for _, scenario := range app.Behaviors {
		if scenario.Given == nil {
			continue
		}
		store, ok := app.Symbols.Stores[model.ParseRef(scenario.Given.Target).Root]
		if !ok {
			continue
		}
		shape, ok := app.ElementModel(store.ValueType)
		if !ok {
			continue
		}
		var elements []map[string]any
		if err := json.Unmarshal([]byte(scenario.Given.Value), &elements); err != nil {
			continue
		}
		for _, element := range elements {
			errs = append(errs, checkElement(scenario.ID, shape, element)...)
		}
	}
	return errs
}

func checkElement(scenarioID string, shape model.Model, element map[string]any) []error {
	var errs []error
	for _, key := range order.Keys(element) {
		if _, ok := shape.Field(key); !ok {
			errs = append(errs, fmt.Errorf("behaviors.yaml > %s: %s has no field %q", scenarioID, shape.Name, key))
		}
	}
	for _, f := range shape.Fields {
		if f.Optional {
			continue
		}
		if _, ok := element[f.Name]; !ok {
			errs = append(errs, fmt.Errorf("behaviors.yaml > %s: %s needs %q, which the given does not set", scenarioID, shape.Name, f.Name))
		}
	}
	return errs
}
