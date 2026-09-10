package model

// KindActionSubject is the kind of a native subject a behavior can address in
// a `then`: `navigator`, and whatever else the action catalog grows. It is
// registered like a store or a widget so that one lookup answers "what is this
// name" for every root a scenario can write.
const KindActionSubject = "action subject"

// ActionBinding is the resolved link between a widget event and the action it
// runs on something that is not a store: "pressing addTaskButton pushes the
// addTask route".
//
// It is the sibling of Binding, and separate from it on purpose. A store
// action changes the app's own state and is written by the implement stage; an
// action here reaches outside the app and its call is fixed by the catalog. A
// widget event can do both, which is why a wrapper reads both lists.
type ActionBinding struct {
	Widget  string // addTaskButton
	Param   string // the name the widget exposes: onPressed, or an alias
	Event   string // the catalog prop that name fills: onPressed
	Subject string // navigator
	Verb    string // push
	Arg     string // addTask, or empty for a verb that takes no argument
	// Indexed says the widget is rendered once per row, the same way a store
	// binding is.
	Indexed     bool
	ScenarioIDs []string
}

// FullPath is the widget event that triggers the action.
func (b ActionBinding) FullPath() string { return b.Widget + "." + b.Param }

// Call is the action as a behavior writes it: "navigator.push addTask".
func (b ActionBinding) Call() string {
	if b.Arg == "" {
		return b.Subject + "." + b.Verb
	}
	return b.Subject + "." + b.Verb + " " + b.Arg
}

// ActionBindingsFor returns every action a widget's parameter runs, in
// declaration order. There can be more than one: an event that both writes the
// store and closes a sheet is two scenarios about one press.
func (st SymbolTable) ActionBindingsFor(widget, param string) []ActionBinding {
	var out []ActionBinding
	for _, b := range st.ActionBindings {
		if b.Widget == widget && b.Param == param {
			out = append(out, b)
		}
	}
	return out
}

// ActionBindingsForWidget returns every action bound to any event of a widget.
func (st SymbolTable) ActionBindingsForWidget(widget string) []ActionBinding {
	var out []ActionBinding
	for _, b := range st.ActionBindings {
		if b.Widget == widget {
			out = append(out, b)
		}
	}
	return out
}
