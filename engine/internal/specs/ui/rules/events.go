package uirules

import (
	"fmt"
	"sort"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

// An event is addressed on the widget that declares it, and a widget declares
// exactly two kinds of them:
//
//   - an alias, written where the prop is: `onChanged: taskToggled` makes
//     `taskCheckbox.taskToggled` the address of that checkbox's onChanged
//   - a callback prop of the widget's own root, which needs no alias because
//     there is only one of it: `incrementButton.onPressed`
//
// Everything deeper is reached by naming the catalog widget on the way:
// `addTaskButton.floatingActionButton.onPressed`, and only while that names one
// widget. Two buttons under one row are not told apart by a path, and an alias
// is how you say which one you meant.
//
// The point of all three is that a spec cannot address something that is not
// there. `addTaskButton.onWiggle` used to generate a parameter that nothing
// rendered, a button wired to nothing, and a test that failed on a value.

// EventAddress is one name a behavior may use for an event, and the catalog
// prop it stands for.
type EventAddress struct {
	Name string // what a behavior writes: "onPressed", "onAddTask"
	Prop string // what the target wires: "onPressed"
	Kind string // the catalog widget that carries the prop
	// OnRoot says the event belongs to the named widget itself rather than to
	// something inside it. It decides what a test taps: the widget, or the one
	// inner widget the alias names.
	OnRoot bool
}

// AddressableEvents lists every event of comp a behavior may name, sorted by
// the name it is addressed by.
func AddressableEvents(comp model.UIComponent, c *catalog.Catalog) []EventAddress {
	aliased := make(map[string]bool)
	var out []EventAddress
	for _, v := range model.UniqueVariables(comp.Variables) {
		if v.Prop == "" || !catalog.PropType(v.Type).IsCallback() {
			continue
		}
		aliased[v.Prop] = true
		out = append(out, EventAddress{
			Name:   v.Name,
			Prop:   v.Prop,
			Kind:   comp.Kind,
			OnRoot: comp.Props[v.Prop] == v.Name,
		})
	}

	// A root prop is addressable under its own name, because a widget has one
	// root and there is nothing to tell apart. An aliased prop is not: the
	// alias is its name now, and two names for one thing is how a spec starts
	// disagreeing with itself.
	if sym, ok := c.Find(comp.Kind); ok {
		for _, prop := range sym.Props {
			if !prop.Type.IsCallback() || aliased[prop.Name] {
				continue
			}
			out = append(out, EventAddress{Name: prop.Name, Prop: prop.Name, Kind: comp.Kind, OnRoot: true})
		}
	}

	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })
	return out
}

// ResolveEvent turns the members of a behavior's reference into the prop it
// addresses on comp. Row selectors are dropped on the way: which row fired an
// event is not part of which event it is.
//
// It reports an error naming what is addressable rather than resolving to
// something plausible, because every one of these used to generate a widget
// that compiled and did nothing.
func ResolveEvent(comp model.UIComponent, members []string, c *catalog.Catalog) (EventAddress, error) {
	path := make([]string, 0, len(members))
	for _, m := range members {
		if !model.IsRowSelector(m) {
			path = append(path, m)
		}
	}
	switch len(path) {
	case 0:
		return EventAddress{}, fmt.Errorf("%q names no event", comp.Name)
	case 1:
		return resolveOwnEvent(comp, path[0], c)
	default:
		return resolvePath(comp, path, c)
	}
}

func resolveOwnEvent(comp model.UIComponent, name string, c *catalog.Catalog) (EventAddress, error) {
	events := AddressableEvents(comp, c)
	for _, e := range events {
		if e.Name == name {
			return e, nil
		}
	}
	return EventAddress{}, fmt.Errorf("%s has no event %q. %s", comp.Name, name, suggest(comp, events))
}

// resolvePath walks `widget.kind.prop`, which is how a prop of a widget inside
// another one is reached when it has no alias.
func resolvePath(comp model.UIComponent, path []string, c *catalog.Catalog) (EventAddress, error) {
	kind, prop := path[len(path)-2], path[len(path)-1]

	if alias := aliasFor(comp, prop); alias != "" {
		return EventAddress{}, fmt.Errorf("%s: %s.%s is named %q, so address it as %s.%s",
			comp.Name, kind, prop, alias, comp.Name, alias)
	}

	matches := 0
	for _, node := range nodesOfKind(comp, kind) {
		if c.PropType(node.Kind, prop).IsCallback() {
			matches++
		}
	}

	switch matches {
	case 1:
		return EventAddress{Name: prop, Prop: prop, Kind: kind, OnRoot: comp.Kind == kind}, nil
	case 0:
		return EventAddress{}, fmt.Errorf("%s has no %s with a %q. %s", comp.Name, kind, prop, suggest(comp, AddressableEvents(comp, c)))
	default:
		return EventAddress{}, fmt.Errorf("%s has %d %s widgets, so %q does not say which one. Name the one you mean where it is declared, e.g. `%s: {onPressed: onSomething}`, then use %s.onSomething",
			comp.Name, matches, kind, strings.Join(path, "."), kind, comp.Name)
	}
}

// nodesOfKind collects the widgets of one catalog kind inside comp, including
// comp itself: a named widget's root is the kind it is written as.
func nodesOfKind(comp model.UIComponent, kind string) []model.UIComponent {
	var out []model.UIComponent
	var walk func(model.UIComponent)
	walk = func(node model.UIComponent) {
		if node.Kind == kind {
			out = append(out, node)
		}
		for _, child := range node.Children {
			walk(child)
		}
	}
	walk(comp)
	return out
}

// aliasFor returns the name a widget gives one of its props, if it gives it
// one. A named widget carries the variables of its whole subtree, so this is
// asked of the named widget rather than of the node inside it.
func aliasFor(node model.UIComponent, prop string) string {
	for _, v := range node.Variables {
		if v.Prop == prop {
			return v.Name
		}
	}
	return ""
}

func suggest(comp model.UIComponent, events []EventAddress) string {
	if len(events) == 0 {
		return fmt.Sprintf("%s declares no events. Name the prop you mean where it is declared, e.g. `%s: {onPressed: onSomething}`, then use %s.onSomething",
			comp.Name, comp.Kind, comp.Name)
	}
	names := make([]string, 0, len(events))
	for _, e := range events {
		names = append(names, e.Name)
	}
	return "Its events are: " + strings.Join(names, ", ")
}
