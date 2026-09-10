package build

import (
	"fmt"

	"github.com/pietroid/metacode/engine/internal/behavior/rules"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
	"github.com/pietroid/metacode/engine/internal/specs/ui/rules"
)

// Resolve cross-references all named symbols in the app, classifies them, and
// reports undefined or conflicting names.
//
// It populates the symbol table with stores, widgets, actions, events, and
// variables derived from the specs. For the MVP it only supports dot-notation
// chains of depth 1 or 2 (e.g. store.action, widget.event, store.field).
func Resolve(app *model.App, c *catalog.Catalog) error {
	// Reset derived collections so Resolve is idempotent.
	app.Symbols.Stores = make(map[string]model.Store, len(app.Stores))
	app.Symbols.Widgets = make(map[string]model.UIComponent, len(app.UI))
	app.Symbols.Events = make(map[string]model.EventRef)
	app.Symbols.Bindings = nil

	for _, s := range app.Stores {
		app.Symbols.Stores[s.Name] = s
	}

	for _, w := range app.UI {
		app.Symbols.Widgets[w.Name] = w
	}

	for _, b := range app.Behaviors {
		if err := resolveBehavior(app, b, c); err != nil {
			return err
		}
	}

	applyWidgetVariableTypes(app)

	// Bindings need the symbol table complete, so they resolve last.
	return behaviorrules.ResolveBindings(app)
}

// applyWidgetVariableTypes writes back what the behaviors just said: a variable
// a scenario compared to a widget holds a widget, not text. The type lives on
// the component so every generator reads the same answer, rather than each one
// re-deriving it from the symbol table.
func applyWidgetVariableTypes(app *model.App) {
	for i, comp := range app.UI {
		for j, v := range comp.Variables {
			if sym, ok := app.Symbols.Lookup(comp.Name + "." + v.Name); ok && sym.Kind == model.KindWidgetVariable {
				app.UI[i].Variables[j].Type = model.TypeWidget
			}
		}
		app.Symbols.Widgets[comp.Name] = app.UI[i]
	}
}

func resolveBehavior(app *model.App, b model.BehaviorScenario, c *catalog.Catalog) error {
	if err := resolveAssertion(app, b.Given, c); err != nil {
		return fmt.Errorf("scenario %q given: %w", b.ID, err)
	}
	if err := resolveAssertion(app, b.Then, c); err != nil {
		return fmt.Errorf("scenario %q then: %w", b.ID, err)
	}
	if b.When != "" {
		if err := resolveWhen(app, b.When, c); err != nil {
			return fmt.Errorf("scenario %q when: %w", b.ID, err)
		}
	}
	return nil
}

func resolveAssertion(app *model.App, a *model.Assertion, c *catalog.Catalog) error {
	if a == nil {
		return nil
	}
	ref := model.ParseRef(a.Target)
	if err := checkRefShape(ref, a.Target); err != nil {
		return err
	}

	root := ref.Root
	if sym, ok := app.Symbols.Lookup(root); ok {
		switch sym.Kind {
		case "store":
			if len(ref.Members) == 0 {
				return fmt.Errorf("store %q cannot be used as a whole value", root)
			}
			// model.Store field access is valid for assertions.
			return nil
		case "widget":
			if len(ref.Members) == 0 {
				return fmt.Errorf("widget %q cannot be used as a whole value", root)
			}
			// A widget member in an assertion is a variable the widget renders.
			// When the value names another widget, the variable holds a widget
			// rather than a string, and the UI generator has no other way to
			// know: `body: homeContent` says nothing about what homeContent is.
			if sym, ok := app.Symbols.Lookup(a.Value); ok && sym.Kind == "widget" {
				app.Symbols.Register(a.Target, model.KindWidgetVariable)
			}
			return nil
		}
	}

	if c.IsKnown(root) {
		return fmt.Errorf("catalog widget %q cannot be asserted on directly", root)
	}

	return fmt.Errorf("undefined symbol %q in assertion %q", root, a.Target)
}

// checkRefShape states how deep a path may go. A row selector buys one extra
// segment and only one: `taskStore.value.first.done` and `taskTile.first.title`
// are the deepest things the specs can say, because a row of a row has no
// meaning while a list holds values rather than lists.
func checkRefShape(ref model.Ref, raw string) error {
	rows := 0
	for _, m := range ref.Members {
		if model.IsRowSelector(m) {
			rows++
		}
	}
	if rows > 1 {
		return fmt.Errorf("unsupported path %q (only one row selector is supported)", raw)
	}
	if len(ref.Members) > 2+rows {
		return fmt.Errorf("unsupported path %q (too deep)", raw)
	}
	return nil
}

func resolveWhen(app *model.App, when string, c *catalog.Catalog) error {
	ref := model.ParseRef(when)
	if err := checkRefShape(ref, when); err != nil {
		return err
	}

	root := ref.Root
	sym, ok := app.Symbols.Lookup(root)
	if !ok {
		return fmt.Errorf("undefined symbol %q in when %q", root, when)
	}

	if len(ref.Members) == 0 {
		// A bare symbol in when must be an action or event already registered.
		if sym.Kind != "action" && sym.Kind != "event" {
			return fmt.Errorf("%q is a %q, expected an action or event reference", root, sym.Kind)
		}
		return nil
	}

	switch sym.Kind {
	case "store":
		// The kind is what callers read; "counterStore.increment" is an action.
		app.Symbols.Register(when, "action")
	case "widget":
		// What the spec wrote is an address, and what the target wires is a
		// prop. An alias is the address of the prop it was declared on, so the
		// two are only the same word when the widget's own root carries it.
		// See uirules.ResolveEvent.
		addressed, err := uirules.ResolveEvent(app.Symbols.Widgets[root], ref.Members, c)
		if err != nil {
			return err
		}
		event := model.EventRef{
			FullPath: when,
			Widget:   root,
			Address:  addressed.Name,
			Event:    addressed.Prop,
			OnRoot:   addressed.OnRoot,
		}
		app.Symbols.Events[when] = event
		app.Symbols.Register(when, "event")
	default:
		return fmt.Errorf("%q is a %q, expected a store or widget reference", root, sym.Kind)
	}
	return nil
}
