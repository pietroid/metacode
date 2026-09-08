package ir

import (
	"fmt"
	"strings"

	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
)

// Resolve cross-references all named symbols in the IR, classifies them, and
// reports undefined or conflicting names.
//
// It populates the symbol table with stores, widgets, actions, events, and
// variables derived from the specs. For the MVP it only supports dot-notation
// chains of depth 1 or 2 (e.g. store.action, widget.event, store.field).
func (ir *IR) Resolve(c *catalog.Catalog) error {
	// Reset derived collections so Resolve is idempotent.
	ir.Symbols.Stores = make(map[string]Store, len(ir.Stores))
	ir.Symbols.Widgets = make(map[string]UIComponent, len(ir.UI))
	ir.Symbols.Actions = make(map[string]ActionRef)
	ir.Symbols.Events = make(map[string]EventRef)
	ir.Symbols.Variables = make(map[string]VariableRef)

	for _, s := range ir.Stores {
		ir.Symbols.Stores[s.Name] = s
	}

	for _, w := range ir.UI {
		ir.Symbols.Widgets[w.Name] = w
		for _, v := range w.Variables {
			ir.Symbols.Variables[v] = VariableRef{Name: v}
		}
	}

	for _, b := range ir.Behaviors {
		if err := ir.resolveBehavior(b, c); err != nil {
			return err
		}
	}

	return nil
}

func (ir *IR) resolveBehavior(b BehaviorScenario, c *catalog.Catalog) error {
	if err := ir.resolveAssertion(b.Given, c); err != nil {
		return fmt.Errorf("scenario %q given: %w", b.ID, err)
	}
	if err := ir.resolveAssertion(b.Then, c); err != nil {
		return fmt.Errorf("scenario %q then: %w", b.ID, err)
	}
	if b.When != "" {
		if err := ir.resolveWhen(b.When); err != nil {
			return fmt.Errorf("scenario %q when: %w", b.ID, err)
		}
	}
	return nil
}

func (ir *IR) resolveAssertion(a *Assertion, c *catalog.Catalog) error {
	if a == nil {
		return nil
	}
	parts := strings.Split(a.Target, ".")
	if len(parts) == 0 || len(parts) > 2 {
		return fmt.Errorf("unsupported target %q (only depth 1 or 2 is supported)", a.Target)
	}

	root := parts[0]
	if sym, ok := ir.Symbols.Lookup(root); ok {
		switch sym.Kind {
		case "store":
			if len(parts) == 1 {
				return fmt.Errorf("store %q cannot be used as a whole value", root)
			}
			// Store field access is valid for assertions.
			return nil
		case "widget":
			if len(parts) == 1 {
				return fmt.Errorf("widget %q cannot be used as a whole value", root)
			}
			// Widget variable binding is valid.
			ir.Symbols.Variables[parts[1]] = VariableRef{Name: parts[1]}
			return nil
		}
	}

	if c.IsKnown(root) {
		return fmt.Errorf("catalog widget %q cannot be asserted on directly", root)
	}

	return fmt.Errorf("undefined symbol %q in assertion %q", root, a.Target)
}

func (ir *IR) resolveWhen(when string) error {
	parts := strings.Split(when, ".")
	if len(parts) == 0 || len(parts) > 2 {
		return fmt.Errorf("unsupported when expression %q (only depth 1 or 2 is supported)", when)
	}

	root := parts[0]
	sym, ok := ir.Symbols.Lookup(root)
	if !ok {
		return fmt.Errorf("undefined symbol %q in when %q", root, when)
	}

	if len(parts) == 1 {
		// A bare symbol in when must be an action or event already registered.
		if sym.Kind != "action" && sym.Kind != "event" {
			return fmt.Errorf("%q is a %q, expected an action or event reference", root, sym.Kind)
		}
		return nil
	}

	second := parts[1]
	switch sym.Kind {
	case "store":
		ref := ActionRef{FullPath: when, Store: root, Name: second}
		ir.Symbols.Actions[when] = ref
		ir.Symbols.Register(when, "action")
	case "widget":
		ref := EventRef{FullPath: when, Widget: root, Event: second}
		ir.Symbols.Events[when] = ref
		ir.Symbols.Register(when, "event")
	default:
		return fmt.Errorf("%q is a %q, expected a store or widget reference", root, sym.Kind)
	}
	return nil
}
