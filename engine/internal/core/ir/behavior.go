package ir

// BehaviorScenario represents a single scenario from behaviors.yaml.
type BehaviorScenario struct {
	ID          string
	Description string
	GroupPath   []string
	Given       string
	When        string
	Then        string
}

// BehaviorGroup represents a nested group of scenarios.
type BehaviorGroup struct {
	Name     string
	Groups   []BehaviorGroup
	Scenarios []BehaviorScenario
}
