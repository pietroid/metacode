package model

// Binding is the resolved link between a widget event and the store action it
// triggers: "pressing decrementButton runs counterStore.decrement".
//
// It is resolved once, by behavior/rules, and read by every generator that has
// to agree about it.
type Binding struct {
	Widget      string   // decrementButton
	Event       string   // onPressed
	Store       string   // counterStore
	Action      string   // decrement
	ScenarioIDs []string // every scenario that exercises this binding
}

// FullPath is the widget event that triggers the binding.
func (b Binding) FullPath() string { return b.Widget + "." + b.Event }

// BindingFor returns the binding for a widget event, if there is one.
func (st SymbolTable) BindingFor(widget, event string) (Binding, bool) {
	for _, b := range st.Bindings {
		if b.Widget == widget && b.Event == event {
			return b, true
		}
	}
	return Binding{}, false
}

// BindingsForStore returns every binding that drives the named store, in
// declaration order.
func (st SymbolTable) BindingsForStore(store string) []Binding {
	var out []Binding
	for _, b := range st.Bindings {
		if b.Store == store {
			out = append(out, b)
		}
	}
	return out
}
