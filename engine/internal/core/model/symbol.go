package model

// SymbolTable registers all declared symbols and their kinds.
type SymbolTable struct {
	Symbols map[string]Symbol
	Stores  map[string]Store
	Widgets map[string]UIComponent
	Events  map[string]EventRef

	// Bindings link widget events to the store actions they run. See binding.go.
	Bindings []Binding
}

// KindWidgetVariable is the kind of a variable that holds a widget rather than
// a value, registered under "<widget>.<variable>".
const KindWidgetVariable = "widget variable"

// Symbol is a named entity referenced by the specs.
type Symbol struct {
	Name string
	Kind string // "store", "widget", "action", "variable", "model", "enum", KindWidgetVariable
}

// EventRef is a widget event a behavior referenced, resolved.
//
// Address is the name the widget answers to, which is an alias when the spec
// gave the prop one. Event is the prop that name stands for. They differ
// whenever a widget holds more than one of the same catalog widget, which is
// exactly when the difference matters: two buttons in a row are two addresses
// and one prop.
type EventRef struct {
	FullPath string
	Widget   string
	Address  string
	Event    string
	// OnRoot says the event belongs to the named widget itself rather than to
	// one of the widgets inside it.
	OnRoot bool
}

// NewSymbolTable creates an empty symbol table.
func NewSymbolTable() SymbolTable {
	return SymbolTable{
		Symbols: make(map[string]Symbol),
		Stores:  make(map[string]Store),
		Widgets: make(map[string]UIComponent),
		Events:  make(map[string]EventRef),
	}
}

// Register adds a symbol to the table.
func (st *SymbolTable) Register(name, kind string) {
	st.Symbols[name] = Symbol{Name: name, Kind: kind}
}

// Lookup returns a symbol and whether it was found.
func (st SymbolTable) Lookup(name string) (Symbol, bool) {
	s, ok := st.Symbols[name]
	return s, ok
}
