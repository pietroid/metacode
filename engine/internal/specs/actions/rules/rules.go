// Package actionrules interprets the action half of a behavior: a `then`
// written as "<subject> should <verb> <argument>", and the widget event that
// runs it.
//
// An action is verified, not expected. `counterStore.value should be 6` is a
// fact about state the app settled on; `navigator should push addTask` is a
// call the app made, and the generated test checks the call happened exactly
// once. Once is the default and there is no way to write anything else yet,
// which is deliberate: a verification that passes on a double push hides the
// most common navigation bug there is, and loosening it later is compatible
// with every spec written under it.
package actionrules

import (
	"fmt"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/actions/catalog"
	"github.com/pietroid/metacode/engine/internal/specs/ui/rules"
)

// Register puts every subject in the symbol table, so that one lookup answers
// what the root of a path is, whether it is a store, a widget or a native.
func Register(c *actioncatalog.Catalog, st *model.SymbolTable) {
	for _, name := range c.Names() {
		st.Register(name, model.KindActionSubject)
	}
}

// CheckAssertion reports whether a `then` naming a subject is one the catalog
// can answer: the verb exists, and its argument is the shape the verb takes.
//
// An unknown route is caught here rather than in the generator, for the same
// reason an unknown icon is: the vocabulary is closed, so a name that is not
// in it is a typo the author can fix.
func CheckAssertion(app *model.App, a *model.Assertion, c *actioncatalog.Catalog) error {
	subject, ok := c.Find(a.Target)
	if !ok {
		return fmt.Errorf("%q is not an action subject. They are: %s", a.Target, strings.Join(c.Names(), ", "))
	}
	verb, ok := subject.Verb(a.Verb)
	if !ok {
		return fmt.Errorf("%s cannot %q. Its actions are: %s", subject.Name, a.Verb, strings.Join(subject.VerbNames(), ", "))
	}

	switch verb.Arg {
	case actioncatalog.ArgNone:
		if a.Value != "" {
			return fmt.Errorf("%s %s takes nothing, so %q is one word too many", subject.Name, verb.Name, a.Value)
		}
	case actioncatalog.ArgRoute:
		if a.Value == "" {
			return fmt.Errorf("%s %s needs a route to %s, e.g. `%s should %s addTask`", subject.Name, verb.Name, verb.Name, subject.Name, verb.Name)
		}
		if !app.Navigation.Declared() {
			return fmt.Errorf("%s %s %s: this project declares no routes. Add navigation.yaml", subject.Name, verb.Name, a.Value)
		}
		if _, ok := app.Navigation.Route(a.Value); !ok {
			return fmt.Errorf("%s %s %s: navigation.yaml declares no route %q", subject.Name, verb.Name, a.Value, a.Value)
		}
	case actioncatalog.ArgText:
		if a.Value == "" {
			return fmt.Errorf("%s %s needs a value", subject.Name, verb.Name)
		}
	}
	return nil
}

// CheckScenario reports what an action assertion needs from the rest of its
// scenario: something that fires it.
//
// An action with no `when` would compile to a test that pumps the app and
// checks a call nobody made. That is the vacuous assertion the engine refuses
// everywhere else. See AGENTS.md, "A test with no interaction is not a test".
func CheckScenario(app *model.App, s model.BehaviorScenario, c *actioncatalog.Catalog) error {
	if s.GivenRoute != "" {
		if !app.Navigation.Declared() {
			return fmt.Errorf("`%s: %s` starts the app on a route, and this project declares none. Add navigation.yaml", model.GivenRouteTarget, s.GivenRoute)
		}
		if _, ok := app.Navigation.Route(s.GivenRoute); !ok {
			return fmt.Errorf("`%s: %s`: navigation.yaml declares no route %q", model.GivenRouteTarget, s.GivenRoute, s.GivenRoute)
		}
		if s.GivenRoute == app.Navigation.InitialRoute {
			return fmt.Errorf("`%s: %s` is where the app already opens, so the scenario says nothing by starting there", model.GivenRouteTarget, s.GivenRoute)
		}
	}
	if s.Then == nil || s.Then.IsState() {
		return nil
	}
	if !c.IsKnown(s.Then.Target) {
		return nil
	}
	if s.When == "" {
		return fmt.Errorf("`%s` is an action, so the scenario needs a `when` that runs it", s.Then.Sentence())
	}
	if _, ok := app.Symbols.Events[s.When]; !ok {
		return fmt.Errorf("`%s` is run by a widget event, and `when: %s` is not one. An action reaches the app through the widget that fires it", s.Then.Sentence(), s.When)
	}
	return nil
}

// ResolveActionBindings derives one binding per widget event that runs an
// action. It is the sibling of behaviorrules.ResolveBindings, and the two are
// separate lists for the same reason a store action and a native action are
// separate concepts: one is written by the implement stage, the other is
// spelled by the catalog.
//
// Scenarios that share a widget event and an action share a binding, so two
// scenarios about one press do not wire it twice.
func ResolveActionBindings(app *model.App, c *actioncatalog.Catalog) error {
	index := make(map[string]int)
	var bindings []model.ActionBinding
	rows := uirules.RowWidgets(app.UI, app.Symbols)

	for _, b := range app.Behaviors {
		if b.Then == nil || b.Then.IsState() || !c.IsKnown(b.Then.Target) {
			continue
		}
		event, ok := app.Symbols.Events[b.When]
		if !ok {
			continue
		}

		key := strings.Join([]string{event.Widget, event.Address, b.Then.Target, b.Then.Verb, b.Then.Value}, ".")
		if i, seen := index[key]; seen {
			bindings[i].ScenarioIDs = append(bindings[i].ScenarioIDs, b.ID)
			continue
		}
		index[key] = len(bindings)
		bindings = append(bindings, model.ActionBinding{
			Widget:      event.Widget,
			Param:       event.Address,
			Event:       event.Event,
			Subject:     b.Then.Target,
			Verb:        b.Then.Verb,
			Arg:         b.Then.Value,
			Indexed:     rows[event.Widget],
			ScenarioIDs: []string{b.ID},
		})
	}

	app.Symbols.ActionBindings = bindings
	return nil
}
