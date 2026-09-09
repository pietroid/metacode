package model

// Assertion represents a condition or expectation in a behavior scenario. A
// `then` writes it as "<target> should be <value>"; a `given` writes it as a
// YAML mapping, "<target>: <value>", where the colon is the operator.
type Assertion struct {
	Target string // e.g. "counterStore.value"
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
