package ir

import (
	"fmt"
	"strings"
)

// ParseAssertion parses a simple assertion string into an Assertion.
//
// It accepts the following operators (case-sensitive for the MVP):
//   - " should be "
//   - " is "
//   - " = "
//
// Whitespace around the operator is required so that values containing the
// operator text are not split incorrectly.
func ParseAssertion(s string) (*Assertion, bool, error) {
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
		return &Assertion{Target: target, Op: o.op, Value: value}, true, nil
	}

	return nil, true, fmt.Errorf("malformed assertion %q (expected \"<target> should be <value>\", \"<target> is <value>\", or \"<target> = <value>\")", s)
}

// ParseBehaviorScenario converts the raw string fields of a behavior scenario
// into the structured BehaviorScenario representation.
func ParseBehaviorScenario(id, description string, groupPath []string, givenRaw, whenRaw, thenRaw string) (BehaviorScenario, error) {
	given, _, err := ParseAssertion(givenRaw)
	if err != nil {
		return BehaviorScenario{}, fmt.Errorf("scenario %q: given: %w", id, err)
	}

	then, hasThen, err := ParseAssertion(thenRaw)
	if err != nil {
		return BehaviorScenario{}, fmt.Errorf("scenario %q: then: %w", id, err)
	}
	if !hasThen {
		return BehaviorScenario{}, fmt.Errorf("scenario %q: missing then", id)
	}

	return BehaviorScenario{
		ID:          id,
		Description: description,
		GroupPath:   groupPath,
		Given:       given,
		When:        strings.TrimSpace(whenRaw),
		Then:        then,
	}, nil
}
