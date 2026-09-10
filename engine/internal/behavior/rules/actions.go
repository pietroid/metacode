package behaviorrules

import "github.com/pietroid/metacode/engine/internal/core/model"

// StoreAction is one method a store's generated class must expose, together
// with the scenarios that specify what it does.
//
// It lives here, in the behavior rules, because an action is a behavior fact:
// which actions a store has comes from the widget events bound to it and from
// the scenarios that name it, never from the store's own declaration. See
// AGENTS.md, "The action a widget event runs comes from the spec".
//
// Two generators read it. The data generator writes the signatures, and the
// implement stage checks a preserved file still declares them, which is the
// same question and so has to have one answer.
type StoreAction struct {
	Name string
	// Indexed actions are run by a widget rendered once per row, so they take
	// the row. The signature is the contract the implement stage writes a body
	// for, and a contract the model has to correct is not one.
	Indexed   bool
	Scenarios []model.BehaviorScenario
}

// StoreActions gathers the actions a store must expose. They come from two
// places, both of them the spec: a widget event bound to the store, resolved
// in ResolveBindings, and an explicit "when: storeName.action".
//
// Nothing is inferred from the store's type. See AGENTS.md, "A store action
// body is business logic, so no generator writes it".
func StoreActions(app *model.App, store model.Store) []StoreAction {
	index := make(map[string]int)
	var actions []StoreAction

	add := func(name string, indexed bool, scenarioID string) {
		i, ok := index[name]
		if !ok {
			index[name] = len(actions)
			actions = append(actions, StoreAction{Name: name})
			i = len(actions) - 1
		}
		actions[i].Indexed = actions[i].Indexed || indexed
		if s, ok := app.ScenarioByID(scenarioID); ok {
			actions[i].Scenarios = append(actions[i].Scenarios, s)
		}
	}

	for _, b := range app.Symbols.BindingsForStore(store.Name) {
		for _, id := range b.ScenarioIDs {
			add(b.Action, b.Indexed, id)
		}
	}

	for _, b := range app.Behaviors {
		root, action := model.SplitRef(b.When)
		if root == store.Name && action != "" {
			add(action, false, b.ID)
		}
	}

	return actions
}
