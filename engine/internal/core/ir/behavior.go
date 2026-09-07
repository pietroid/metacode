package ir

// Assertion represents a simple condition or expectation in a behavior scenario.
// Supported forms:
//   - "<target> should be <value>"  (then)
//   - "<target> is <value>"         (given, alias for should be)
//   - "<target> = <value>"          (shorthand used by some specs)
type Assertion struct {
	Target string // e.g. "counterStore.value"
	Op     string // "should be", "is", "="
	Value  string // "6"
}

// BehaviorScenario represents a single scenario from behaviors.yaml.
type BehaviorScenario struct {
	ID          string
	Description string
	GroupPath   []string
	Given       *Assertion
	When        string
	Then        *Assertion
}

// BehaviorGroup represents a nested group of scenarios.
type BehaviorGroup struct {
	Name      string
	Groups    []BehaviorGroup
	Scenarios []BehaviorScenario
}
