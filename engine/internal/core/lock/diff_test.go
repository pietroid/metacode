package lock

import (
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/build"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

// The counter app as YAML text, so a test can change one character of a spec
// file the way an author would and see what the diff makes of it. The point of
// several of these tests is that the change is textual and the diff is not.
const counterProject = "name: counter_app\ndescription: A simple counter app\n"

const counterData = `stores:
  counterStore:
    value: int
    initialValue: 0
    strategy: ephemeral
`

const counterUI = `widgets:
  homePage:
    scaffold:
      appBar:
        title: Counter App
      body:
        center:
          column:
            - text: counterValue
            - incrementButton
  incrementButton:
    elevatedButton:
      child: Increment
`

const counterBehaviors = `counterStore:
  increments from 0:
    given:
      counterStore.value: 0
    when: incrementButton.onPressed
    then: counterStore.value should be 1
`

type specText struct {
	project, data, ui, behaviors string
}

func counterSpecs() specText {
	return specText{counterProject, counterData, counterUI, counterBehaviors}
}

func (s specText) parse(t *testing.T) spec.RawSpecs {
	t.Helper()
	raw := spec.RawSpecs{}
	for _, f := range []struct {
		text string
		into *map[string]any
	}{
		{s.project, &raw.Project},
		{s.data, &raw.Data},
		{s.ui, &raw.UI},
		{s.behaviors, &raw.Behaviors},
	} {
		parsed, err := parseYAML(f.text)
		if err != nil {
			t.Fatalf("parse spec: %v", err)
		}
		*f.into = parsed
	}
	return raw
}

func (s specText) app(t *testing.T) *model.App {
	t.Helper()
	app, err := build.App(s.parse(t))
	if err != nil {
		t.Fatalf("build: %v", err)
	}
	if err := build.Resolve(&app, catalog.Default()); err != nil {
		t.Fatalf("resolve: %v", err)
	}
	return &app
}

// diffOf compares two spec texts the way a run does: the first is what a lock
// holds, the second is what the author now has.
func diffOf(t *testing.T, was, now specText) Result {
	t.Helper()
	result, err := Diff(Locked{Specs: was.parse(t), Stamp: Stamp{RulesHash: "r"}}, now.app(t), catalog.Default(), "r")
	if err != nil {
		t.Fatalf("diff: %v", err)
	}
	return result
}

func TestUnchangedSpecsProduceNoChange(t *testing.T) {
	if got := diffOf(t, counterSpecs(), counterSpecs()); len(got.Changes) != 0 {
		t.Errorf("expected no change, got %v", got.Changes)
	}
}

// TestCommentsAndOrderAreNotChanges is the reason the diff runs on the model
// and not on the text. Both edits below are the whole point of keeping the
// lock in YAML while comparing something else.
func TestCommentsAndOrderAreNotChanges(t *testing.T) {
	commented := counterSpecs()
	commented.data = "# the one store this app has\n" + counterData + "\n# end\n"
	if got := diffOf(t, counterSpecs(), commented); len(got.Changes) != 0 {
		t.Errorf("a comment counted as a change: %v", got.Changes)
	}

	reordered := counterSpecs()
	reordered.project = "description: A simple counter app\nname: counter_app\n"
	if got := diffOf(t, counterSpecs(), reordered); len(got.Changes) != 0 {
		t.Errorf("reordering two keys counted as a change: %v", got.Changes)
	}
}

func TestAChangedStoreIsOneModification(t *testing.T) {
	now := counterSpecs()
	now.data = strings.Replace(counterData, "initialValue: 0", "initialValue: 3", 1)

	got := diffOf(t, counterSpecs(), now).Changes
	if len(got) != 1 || got[0].Kind != KindStore || got[0].ID != "counterStore" || got[0].Op != OpModified {
		t.Fatalf("expected one modified store, got %v", got)
	}
}

// TestARenameIsARemovalAndAnAddition pins the choice not to guess at identity.
// Nothing downstream can follow a renamed store, so calling it a rename would
// be a nicer word for the same regeneration.
func TestARenameIsARemovalAndAnAddition(t *testing.T) {
	now := counterSpecs()
	now.ui = strings.ReplaceAll(counterUI, "incrementButton", "addButton")
	now.behaviors = strings.ReplaceAll(counterBehaviors, "incrementButton", "addButton")

	var added, removed bool
	for _, c := range diffOf(t, counterSpecs(), now).Changes {
		if c.Kind != KindWidget {
			continue
		}
		added = added || (c.ID == "addButton" && c.Op == OpAdded)
		removed = removed || (c.ID == "incrementButton" && c.Op == OpRemoved)
	}
	if !added || !removed {
		t.Errorf("expected the old name removed and the new one added, got %v", diffOf(t, counterSpecs(), now).Changes)
	}
}

func TestAChangedRulesHashSkipsTheComparison(t *testing.T) {
	specs := counterSpecs()
	result, err := Diff(Locked{Specs: specs.parse(t), Stamp: Stamp{RulesHash: "old"}}, specs.app(t), catalog.Default(), "new")
	if err != nil {
		t.Fatalf("diff: %v", err)
	}
	if len(result.Changes) != 1 || result.Changes[0].Kind != KindRules {
		t.Fatalf("expected one rules change, got %v", result.Changes)
	}
	if result.Previous != nil {
		t.Error("nothing was rebuilt, so there is no previous model to carry")
	}
}

// TestUnbuildableLockIsAnError leaves the caller to decide, and the pipeline
// decides on a full regeneration. Failing here rather than returning an empty
// diff is the important half: an empty diff would silently skip the work.
func TestUnbuildableLockIsAnError(t *testing.T) {
	broken := counterSpecs()
	broken.data = "stores: not-a-map\n"

	if _, err := Diff(Locked{Specs: broken.parse(t), Stamp: Stamp{RulesHash: "r"}}, counterSpecs().app(t), catalog.Default(), "r"); err == nil {
		t.Fatal("expected an error for a lock that no longer builds")
	}
}
