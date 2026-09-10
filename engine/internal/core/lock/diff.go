package lock

import (
	"fmt"
	"reflect"
	"sort"

	"github.com/pietroid/metacode/engine/internal/core/build"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

// Kind is what a change touched.
type Kind string

// The kinds, one per thing a spec can declare that the generated code depends
// on. Project is here because a renamed project renames the package every
// import in the tree uses.
const (
	KindProject  Kind = "project"
	KindStore    Kind = "store"
	KindWidget   Kind = "widget"
	KindScenario Kind = "scenario"
	KindModel    Kind = "model"
	KindRoute    Kind = "route"
	KindRules    Kind = "rules"
)

// Op is what happened to it.
type Op string

// The operations. A rename is an Added and a Removed rather than a third case:
// nothing downstream can follow the identity of a renamed store, so treating
// it as a rename would only be a nicer word for the same regeneration.
const (
	OpAdded    Op = "added"
	OpRemoved  Op = "removed"
	OpModified Op = "modified"
)

// Change is one difference between the locked specs and the current ones.
type Change struct {
	Kind Kind
	ID   string
	Op   Op
}

// Result is a diff and the state it was taken against.
//
// Previous is carried out of the diff because a removal cannot be classified
// without it. A scenario that is gone from the current specs has no bindings
// left to follow, and the only record of which store and which wrapper it used
// to reach is the model the lock rebuilt. Without it, every deletion would
// force a full regeneration, which is exactly the edit someone iterating on
// behavior makes most often.
//
// It is nil when the rules hash moved, because then nothing was rebuilt.
type Result struct {
	Changes  []Change
	Previous *model.App
}

func (c Change) String() string { return fmt.Sprintf("%s %s %s", c.Kind, c.ID, c.Op) }

// Diff reports what changed between the specs a previous run recorded and the
// app this run built.
//
// The comparison is on the resolved model, never on the YAML text. A text or
// tree diff of the spec files fires on a comment edit and on a reordered key,
// neither of which changes a byte of output, and it cannot answer the question
// the freeze set asks: which wrapper a changed scenario reaches is resolved at
// stage 4, so it is not visible in the text at all.
//
// So the locked specs are rebuilt here, with the current engine's rules, and
// two model.App values are compared. When they no longer build — the spec
// language moved under a lock written by an older engine — there is nothing to
// compare against, and the honest answer is that everything changed.
func Diff(locked Locked, current *model.App, c *catalog.Catalog, rulesHash string) (Result, error) {
	if locked.Stamp.RulesHash != rulesHash {
		return Result{Changes: []Change{{Kind: KindRules, ID: "prompt rules", Op: OpModified}}}, nil
	}

	previous, err := build.App(locked.Specs)
	if err != nil {
		return Result{}, fmt.Errorf("rebuild the locked specs: %w", err)
	}
	if err := build.Resolve(&previous, c); err != nil {
		return Result{}, fmt.Errorf("resolve the locked specs: %w", err)
	}

	var changes []Change
	changes = append(changes, diffProject(previous.Project, current.Project)...)
	changes = append(changes, diffStores(previous.Stores, current.Stores)...)
	changes = append(changes, diffWidgets(previous.UI, current.UI)...)
	changes = append(changes, diffScenarios(previous.Behaviors, current.Behaviors)...)
	changes = append(changes, diffModels(&previous, current)...)
	changes = append(changes, diffRoutes(previous.Navigation, current.Navigation)...)

	sort.Slice(changes, func(i, j int) bool {
		if changes[i].Kind != changes[j].Kind {
			return changes[i].Kind < changes[j].Kind
		}
		return changes[i].ID < changes[j].ID
	})
	return Result{Changes: changes, Previous: &previous}, nil
}

func diffProject(previous, current model.Project) []Change {
	if previous == current {
		return nil
	}
	return []Change{{Kind: KindProject, ID: current.Name, Op: OpModified}}
}

func diffStores(previous, current []model.Store) []Change {
	return compare(KindStore, keyed(previous, func(s model.Store) string { return s.Name }),
		keyed(current, func(s model.Store) string { return s.Name }), sameStore)
}

// sameStore compares by value. InitialValue needs the deep comparison, not
// ==: it comes out of YAML as an any that can hold a map or a slice, and those
// panic on ==.
func sameStore(a, b model.Store) bool {
	return a.ValueType == b.ValueType &&
		a.Strategy == b.Strategy &&
		reflect.DeepEqual(a.InitialValue, b.InitialValue)
}

func diffWidgets(previous, current []model.UIComponent) []Change {
	return compare(KindWidget, keyed(previous, func(c model.UIComponent) string { return c.Name }),
		keyed(current, func(c model.UIComponent) string { return c.Name }), sameWidget)
}

// sameWidget compares a widget's whole subtree. Every part of it reaches the
// generated file, so a nested label is as much a change as a nested button.
// Whether that change reaches a wrapper is a separate question, answered in
// classify.go.
func sameWidget(a, b model.UIComponent) bool {
	return reflect.DeepEqual(a, b)
}

func diffScenarios(previous, current []model.BehaviorScenario) []Change {
	return compare(KindScenario, keyed(previous, func(s model.BehaviorScenario) string { return s.ID }),
		keyed(current, func(s model.BehaviorScenario) string { return s.ID }), sameScenario)
}

// sameScenario compares deeply rather than by printed form. Given and Then
// are pointers, and formatting a struct that holds one prints the address, so
// a scenario would never equal itself and every run would look changed.
func sameScenario(a, b model.BehaviorScenario) bool {
	return reflect.DeepEqual(a, b)
}

// diffModels covers models and enums together: both are shapes a store holds,
// and a change to either reaches the same generated code.
func diffModels(previous, current *model.App) []Change {
	changes := compare(KindModel, keyed(previous.Models, func(m model.Model) string { return m.Name }),
		keyed(current.Models, func(m model.Model) string { return m.Name }),
		deepEqual[model.Model])

	return append(changes, compare(KindModel, keyed(previous.Enums, func(e model.Enum) string { return e.Name }),
		keyed(current.Enums, func(e model.Enum) string { return e.Name }),
		deepEqual[model.Enum])...)
}

// diffRoutes compares the route table. The initial route is carried on every
// route rather than compared on its own: which route the app opens on reaches
// the generated router, so a change to it is a change to the table.
func diffRoutes(previous, current model.Navigation) []Change {
	key := func(r model.Route) string { return r.Name }
	same := func(a, b model.Route) bool {
		return a == b && (previous.InitialRoute == current.InitialRoute)
	}
	return compare(KindRoute, keyed(previous.Routes, key), keyed(current.Routes, key), same)
}

// deepEqual is reflect.DeepEqual at one type, so it can be handed to compare.
func deepEqual[T any](a, b T) bool { return reflect.DeepEqual(a, b) }

// keyed indexes a slice by the name its kind is identified by. Order is
// dropped on purpose: reordering entries in a spec file changes nothing the
// engine generates, and a positional comparison would report every entry after
// an insertion as modified.
func keyed[T any](items []T, id func(T) string) map[string]T {
	out := make(map[string]T, len(items))
	for _, item := range items {
		out[id(item)] = item
	}
	return out
}

// compare is the whole diff, said once. Everything a spec declares is a named
// thing that is either gone, new, or different, so each kind supplies its
// identity and its equality and this supplies the rest.
func compare[T any](kind Kind, previous, current map[string]T, same func(a, b T) bool) []Change {
	var changes []Change
	for id, was := range previous {
		now, ok := current[id]
		switch {
		case !ok:
			changes = append(changes, Change{Kind: kind, ID: id, Op: OpRemoved})
		case !same(was, now):
			changes = append(changes, Change{Kind: kind, ID: id, Op: OpModified})
		}
	}
	for id := range current {
		if _, ok := previous[id]; !ok {
			changes = append(changes, Change{Kind: kind, ID: id, Op: OpAdded})
		}
	}
	return changes
}
