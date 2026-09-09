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

// op is the only assertion operator. A `given` writes it as the YAML colon, a
// `then` spells it out, so an assertion carries a target and a value and never
// a choice of operator.
const op = "should be"

// ParseGiven reads a `given` block, which is a mapping of one target to the
// value it holds:
//
//	given:
//	  counterStore.value: 0
//
// The colon is the operator, so the value stays YAML — a list or a mapping
// needs no quoting and no second parser.
func ParseGiven(raw any) (*model.Assertion, error) {
	if raw == nil {
		return nil, nil
	}
	m, ok := raw.(map[string]any)
	if !ok {
		return nil, fmt.Errorf("given must be a mapping of a target to its value, as in `given:` then `counterStore.value: 0`; got %T", raw)
	}
	if len(m) == 0 {
		return nil, nil
	}
	if len(m) > 1 {
		return nil, fmt.Errorf("given names %d targets, expected one", len(m))
	}
	target := order.Keys(m)[0]
	return &model.Assertion{Target: target, Value: formatValue(m[target])}, nil
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
// There is one operator, " should be ", and the whitespace around it is
// required so that a value containing the words is not split incorrectly.
func ParseAssertion(s string) (*model.Assertion, bool, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, false, nil
	}

	idx := strings.Index(s, " "+op+" ")
	if idx == -1 {
		return nil, true, fmt.Errorf("malformed assertion %q (expected \"<target> should be <value>\")", s)
	}

	target := strings.TrimSpace(s[:idx])
	value := unquote(strings.TrimSpace(s[idx+len(op)+2:]))
	if target == "" {
		return nil, true, fmt.Errorf("assertion has empty target: %q", s)
	}
	return &model.Assertion{Target: target, Value: value}, true, nil
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
	given, err := ParseGiven(givenRaw)
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
