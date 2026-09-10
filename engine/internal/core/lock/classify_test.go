package lock

import (
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/plan"
)

// staleOf runs the whole thing a run runs: rebuild the lock, diff, classify.
func staleOf(t *testing.T, was, now specText) plan.Stale {
	t.Helper()
	return Classify(diffOf(t, was, now), now.app(t))
}

func TestNothingChangedNeedsNoModel(t *testing.T) {
	if got := staleOf(t, counterSpecs(), counterSpecs()); !got.Empty() {
		t.Errorf("expected nothing stale, got %+v", got)
	}
}

// TestALayoutChangeNeedsNoModel is the best case the whole feature exists for.
// The dumb widget is regenerated deterministically, the wrapper's constructor
// parameters did not move, so no request is made at all.
func TestALayoutChangeNeedsNoModel(t *testing.T) {
	now := counterSpecs()
	now.ui = strings.Replace(counterUI, "title: Counter App", "title: My Counter", 1)

	got := staleOf(t, counterSpecs(), now)
	if !got.Empty() {
		t.Errorf("a changed appBar title asked for a model: %+v", got)
	}
}

// TestARenamedProjectNeedsNoModel: the project generator owns pubspec,
// main.dart and app.dart, none of which a model writes, and code inside lib
// uses relative imports.
func TestARenamedProjectNeedsNoModel(t *testing.T) {
	now := counterSpecs()
	now.project = "name: counter_app\ndescription: Now with feeling\n"

	if got := staleOf(t, counterSpecs(), now); !got.Empty() {
		t.Errorf("a project description asked for a model: %+v", got)
	}
}

// TestANewVariableUnfreezesTheWrapper is the other side of the layout case.
// A variable is a constructor parameter the wrapper has to fill, so the
// contract moved and the wiring has to be rewritten.
func TestANewVariableUnfreezesTheWrapper(t *testing.T) {
	now := counterSpecs()
	now.ui = strings.Replace(counterUI, "title: Counter App", "title: counterTitle", 1)

	got := staleOf(t, counterSpecs(), now)
	if !got.HasWrapper("homePage") {
		t.Errorf("expected homePage's wrapper to be stale, got %+v", got)
	}
}

func TestAChangedStoreUnfreezesOnlyThatStore(t *testing.T) {
	now := counterSpecs()
	now.data = strings.Replace(counterData, "initialValue: 0", "initialValue: 7", 1)

	got := staleOf(t, counterSpecs(), now)
	if !got.HasStore("counterStore") {
		t.Errorf("expected counterStore to be stale, got %+v", got)
	}
	if len(got.Wrappers) != 0 {
		t.Errorf("a store's initial value reached a wrapper: %+v", got.Wrappers)
	}
}

// TestAChangedScenarioReachesItsStoreAndItsWrapper is the case the lock was
// asked for: edit one behavior, rewrite what that behavior touches.
func TestAChangedScenarioReachesItsStoreAndItsWrapper(t *testing.T) {
	now := counterSpecs()
	now.behaviors = strings.Replace(counterBehaviors, "should be 1", "should be 2", 1)

	got := staleOf(t, counterSpecs(), now)
	if !got.HasStore("counterStore") {
		t.Errorf("expected the store to be stale, got %+v", got)
	}
	if !got.HasWrapper("incrementButton") {
		t.Errorf("expected the button's wrapper to be stale, got %+v", got)
	}
	if got.All {
		t.Error("one scenario should not open the whole app")
	}
}

// TestARemovedScenarioIsFollowedThroughTheLock is why Result carries the model
// it rebuilt. The current specs no longer know the scenario existed, so
// without the old bindings a deletion would force a full regeneration, and
// deleting a scenario is a thing people do while iterating.
func TestARemovedScenarioIsFollowedThroughTheLock(t *testing.T) {
	was := counterSpecs()
	was.behaviors = counterBehaviors + `  also increments from 1:
    given:
      counterStore.value: 1
    when: incrementButton.onPressed
    then: counterStore.value should be 2
`

	got := staleOf(t, was, counterSpecs())
	if got.All {
		t.Fatalf("a deleted scenario forced a full regeneration: %+v", got)
	}
	if !got.HasStore("counterStore") || !got.HasWrapper("incrementButton") {
		t.Errorf("expected the deleted scenario's store and wrapper, got %+v", got)
	}
}

// TestChangedRulesOpenEverything: preserved code was written under the old
// instructions, so nothing about it can be assumed to still hold.
func TestChangedRulesOpenEverything(t *testing.T) {
	specs := counterSpecs()
	result, err := Diff(Locked{Specs: specs.parse(t), Stamp: Stamp{RulesHash: "old"}}, specs.app(t), nil, "new")
	if err != nil {
		t.Fatalf("diff: %v", err)
	}
	got := Classify(result, specs.app(t))
	if !got.All {
		t.Errorf("expected everything to be stale, got %+v", got)
	}
	if len(got.Reasons) == 0 {
		t.Error("a run that opens everything has to say why")
	}
}

// TestEveryStaleSetSaysWhy: a run that quietly skips or quietly widens the
// expensive stage looks like a fast run rather than like a bug.
func TestEveryStaleSetSaysWhy(t *testing.T) {
	now := counterSpecs()
	now.behaviors = strings.Replace(counterBehaviors, "should be 1", "should be 2", 1)

	if got := staleOf(t, counterSpecs(), now); len(got.Reasons) == 0 {
		t.Error("something was marked stale with no reason recorded")
	}
}

// TestTheLayoutCaseIsNotVacuous guards the test above it. If a changed appBar
// title stopped registering as a widget change at all, TestALayoutChangeNeeds
// NoModel would pass for the wrong reason and stop guarding sameContract.
func TestTheLayoutCaseIsNotVacuous(t *testing.T) {
	now := counterSpecs()
	now.ui = strings.Replace(counterUI, "title: Counter App", "title: My Counter", 1)

	var sawWidget bool
	for _, c := range diffOf(t, counterSpecs(), now).Changes {
		sawWidget = sawWidget || (c.Kind == KindWidget && c.ID == "homePage" && c.Op == OpModified)
	}
	if !sawWidget {
		t.Fatal("the diff no longer notices a changed title, so the layout case proves nothing")
	}
}
