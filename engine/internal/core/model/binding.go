package model

// Binding is the resolved link between a widget event and the store action it
// triggers: "pressing decrementButton runs counterStore.decrement".
//
// It is resolved once, by behavior/rules, and read by every generator that has
// to agree about it.
type Binding struct {
	Widget string // decrementButton
	Param  string // the name the widget exposes: onPressed, or an alias
	Event  string // the catalog prop that name fills: onPressed
	Store  string // counterStore
	Action string // decrement
	// Indexed says the widget is rendered once per row, so the action it runs
	// has to be told which row fired it.
	Indexed     bool
	ScenarioIDs []string // every scenario that exercises this binding
}

// FullPath is the widget event that triggers the binding.
func (b Binding) FullPath() string { return b.Widget + "." + b.Param }

// BindingFor returns the binding that fills a widget's parameter, if there is
// one. The parameter is what a wrapper writes, so it is what the lookup is by:
// two buttons in one widget share a prop and never share a parameter.
func (st SymbolTable) BindingFor(widget, param string) (Binding, bool) {
	for _, b := range st.Bindings {
		if b.Widget == widget && b.Param == param {
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
