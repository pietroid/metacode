package model

// VerbBe is the state predicate. Every other verb is an action one of the
// engine's native subjects performs, and the difference is verify against
// expect: `counterStore.value should be 6` is a fact about state that settled,
// `navigator should push addTask` is a call that happened.
const VerbBe = "be"

// Assertion represents a condition or expectation in a behavior scenario.
//
// A `then` writes it as "<target> should <verb> <value>"; a `given` writes it
// as a YAML mapping, "<target>: <value>", where the colon is the operator and
// the verb is always `be`, because a precondition is state.
type Assertion struct {
	Target string // e.g. "counterStore.value", "navigator"
	Verb   string // "be", or a verb the target's action catalog declares
	Value  string // "6", "addTask", or empty for a verb that takes no argument
}

// IsState reports whether the assertion is about a value the app settled on,
// rather than about an action it performed.
func (a Assertion) IsState() bool { return a.Verb == "" || a.Verb == VerbBe }

// Sentence renders the assertion the way the spec wrote it, which is how the
// prompt prints it back.
func (a Assertion) Sentence() string {
	verb := a.Verb
	if verb == "" {
		verb = VerbBe
	}
	if a.Value == "" {
		return a.Target + " should " + verb
	}
	return a.Target + " should " + verb + " " + a.Value
}

// GivenRouteTarget is what a given writes to say where the app starts.
//
// It is a precondition like any other, and a different one from the store: a
// scenario about a button inside a sheet is not testable by seeding a value,
// because the button is not on screen until the app is there. The test drives
// the app to the route the way a user would and starts the scenario from
// there.
const GivenRouteTarget = "navigator.route"

// BehaviorScenario represents a single scenario from behaviors.yaml.
type BehaviorScenario struct {
	ID          string
	Description string
	GroupPath   []string
	Given       *Assertion
	// GivenRoute is the route the app is on when the scenario starts, empty
	// when it starts where the app opens.
	GivenRoute string
	When       string
	Then       *Assertion
}

// BehaviorGroup represents a nested group of scenarios.
type BehaviorGroup struct {
	Name      string
	Groups    []BehaviorGroup
	Scenarios []BehaviorScenario
}
