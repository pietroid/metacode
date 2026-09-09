// Package behaviorrules interprets the behavior spec: it parses scenarios and
// their given/when/then assertions, and resolves which store action a widget
// event runs.
//
// Behaviors are the centerpiece spec — they are what the tests verify and what
// the implement stage is asked to satisfy — which is why they sit at the top
// level rather than beside the other spec kinds.
package behaviorrules

import (
	"fmt"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/order"
)

// ParseAssertion parses a simple assertion string into an model.Assertion.
//
// It accepts the following operators (case-sensitive for the MVP):
//   - " should be "
//   - " is "
//   - " = "
//
// Whitespace around the operator is required so that values containing the
// operator text are not split incorrectly.
func ParseAssertion(s string) (*model.Assertion, bool, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, false, nil
	}

	ops := []struct {
		text string
		op   string
	}{
		{" should be ", "should be"},
		{" is ", "is"},
		{" = ", "="},
	}

	for _, o := range ops {
		idx := strings.Index(s, o.text)
		if idx == -1 {
			continue
		}
		target := strings.TrimSpace(s[:idx])
		value := strings.TrimSpace(s[idx+len(o.text):])
		if target == "" {
			return nil, true, fmt.Errorf("assertion has empty target: %q", s)
		}
		return &model.Assertion{Target: target, Op: o.op, Value: value}, true, nil
	}

	return nil, true, fmt.Errorf("malformed assertion %q (expected \"<target> should be <value>\", \"<target> is <value>\", or \"<target> = <value>\")", s)
}

// ParseBehaviorScenario converts the raw string fields of a behavior scenario
// into the structured model.BehaviorScenario representation.
func ParseBehaviorScenario(id, description string, groupPath []string, givenRaw, whenRaw, thenRaw string) (model.BehaviorScenario, error) {
	given, _, err := ParseAssertion(givenRaw)
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
				stringValue(v, "given"),
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
