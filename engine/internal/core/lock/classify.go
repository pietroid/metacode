package lock

import (
	"fmt"
	"reflect"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
)

// Classify turns a diff into the set of files a model may rewrite.
//
// Every rule here is a best guess, and it is allowed to be. A guess that is
// too narrow is caught by the suite, which runs on every run whatever the diff
// said, and the first repair iteration unfreezes everything. So the cost of
// being wrong is one test run, not a wrong app. What the rules must never do
// is widen quietly: a rule that unfreezes everything for a common edit turns
// the lock back off without saying so, which is why each one records a reason.
func Classify(result Result, current *model.App) plan.Stale {
	var stale plan.Stale
	for _, change := range result.Changes {
		classifyOne(change, result.Previous, current, &stale)
		if stale.All {
			return stale
		}
	}
	return stale
}

// classifyOne is the table. It is a switch over what changed rather than a
// chain of conditions so that adding a spec kind is one case, and so the whole
// policy can be read in one screen.
func classifyOne(change Change, previous, current *model.App, stale *plan.Stale) {
	switch change.Kind {
	case KindRules:
		*stale = plan.Everything("the prompt rules changed since the lock was written")

	case KindProject:
		// Nothing. The project generator owns pubspec, main.dart and app.dart,
		// none of which a model writes, and code inside lib/ uses relative
		// imports, so even a rename does not reach a store or a wrapper.

	case KindStore:
		classifyStore(change, current, stale)

	case KindWidget:
		classifyWidget(change, previous, current, stale)

	case KindScenario:
		classifyScenario(change, previous, current, stale)

	case KindModel:
		classifyModel(change, current, stale)

	case KindRoute:
		classifyRoute(change, previous, current, stale)
	}
}

// classifyStore unfreezes the Cubit of a store whose shape moved. A removed
// store needs nothing: its files are pruned, and a wrapper that pointed at it
// is either gone too or is reported by its own change.
func classifyStore(change Change, current *model.App, stale *plan.Stale) {
	if change.Op == OpRemoved {
		return
	}
	stale.AddStore(change.ID)
	stale.AddReason(fmt.Sprintf("store %s %s", change.ID, change.Op))
}

// classifyWidget is where the best case lives.
//
// A widget's dumb file is regenerated deterministically on every run, so a
// changed label, a changed colour or a reordered column costs nothing and
// needs no model. What the wrapper depends on is narrower: the variables the
// widget exposes, because those are the constructor parameters the wrapper
// fills. When the subtree changed but that contract did not, the wrapper is
// left alone, and a pure layout edit runs with no LLM call at all.
func classifyWidget(change Change, previous, current *model.App, stale *plan.Stale) {
	if change.Op == OpRemoved {
		return
	}
	if change.Op == OpModified && sameContract(previous, current, change.ID) {
		return
	}
	stale.AddWrapper(change.ID)
	stale.AddReason(fmt.Sprintf("widget %s %s", change.ID, change.Op))
}

// sameContract reports whether a widget still exposes the same variables in
// the same order. It is deliberately shallow: the values behind those names
// are behavior, and behavior changes arrive as scenario changes.
func sameContract(previous, current *model.App, name string) bool {
	was, hadIt := componentNamed(previous, name)
	now, hasIt := componentNamed(current, name)
	if !hadIt || !hasIt {
		return false
	}
	return reflect.DeepEqual(model.UniqueVariables(was.Variables), model.UniqueVariables(now.Variables))
}

func componentNamed(app *model.App, name string) (model.UIComponent, bool) {
	if app == nil {
		return model.UIComponent{}, false
	}
	for _, c := range app.UI {
		if c.Name == name {
			return c, true
		}
	}
	return model.UIComponent{}, false
}

// classifyScenario unfreezes everything one scenario reaches.
//
// A scenario's test is rewritten deterministically at stage 8, before any
// model is asked for anything, so "change the test first" is already the
// pipeline's order. What this adds is the second half: only the store and the
// wrappers that scenario touches are opened for rewriting, and every other
// scenario is stated to be passing already.
//
// A removed scenario is followed through the model the lock rebuilt, because
// the current one no longer knows it existed.
func classifyScenario(change Change, previous, current *model.App, stale *plan.Stale) {
	reach(current, change.ID, stale)
	if change.Op != OpAdded {
		reach(previous, change.ID, stale)
	}
	stale.AddReason(fmt.Sprintf("scenario %s %s", change.ID, change.Op))
}

// reach marks every store and wrapper one scenario touches, in app.
//
// The store comes from the scenario's own given and then, which name it
// directly. The wrappers come from the bindings that list the scenario, which
// is the resolved answer to "which widget event does this scenario fire" and
// is the reason the diff runs on the model rather than on the YAML.
func reach(app *model.App, scenarioID string, stale *plan.Stale) {
	if app == nil {
		return
	}

	scenario, ok := app.ScenarioByID(scenarioID)
	if ok {
		for _, assertion := range []*model.Assertion{scenario.Given, scenario.Then} {
			if assertion == nil {
				continue
			}
			if root, _ := model.SplitRef(assertion.Target); isStore(app, root) {
				stale.AddStore(root)
			}
		}
	}

	for _, binding := range app.Symbols.Bindings {
		for _, id := range binding.ScenarioIDs {
			if id != scenarioID {
				continue
			}
			stale.AddStore(binding.Store)
			stale.AddWrapper(binding.Widget)
		}
	}
}

func isStore(app *model.App, name string) bool {
	for _, store := range app.Stores {
		if store.Name == name {
			return true
		}
	}
	return false
}

// classifyRoute unfreezes the wrappers that reach a changed route: the ones
// whose events push it, and the wrapper of the widget it shows.
//
// The router itself is regenerated deterministically on every run, so a
// changed route costs nothing there. What a model wrote is the push, and a
// push that now names a different destination is wiring the specs moved.
func classifyRoute(change Change, previous, current *model.App, stale *plan.Stale) {
	for _, app := range []*model.App{previous, current} {
		if app == nil {
			continue
		}
		for _, binding := range app.Symbols.ActionBindings {
			if binding.Arg == change.ID {
				stale.AddWrapper(binding.Widget)
			}
		}
		if route, ok := app.Navigation.Route(change.ID); ok {
			stale.AddWrapper(route.Child)
		}
	}
	stale.AddReason(fmt.Sprintf("route %s %s", change.ID, change.Op))
}

// classifyModel unfreezes every store that holds the changed shape. Models and
// enums reach generated code only through the stores whose value type names
// them, so nothing else has to be considered.
func classifyModel(change Change, current *model.App, stale *plan.Stale) {
	for _, store := range current.Stores {
		if !holds(store.ValueType, change.ID) {
			continue
		}
		stale.AddStore(store.Name)
		stale.AddReason(fmt.Sprintf("model %s %s", change.ID, change.Op))
	}
}

// holds reports whether a store's value type is the named shape, or a list of
// it. Those are the two forms the data spec allows.
func holds(valueType, name string) bool {
	if valueType == name {
		return true
	}
	element, isList := model.ListElement(valueType)
	return isList && element == name
}
