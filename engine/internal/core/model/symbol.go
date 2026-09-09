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

// Symbol is a named entity referenced by the specs.
type Symbol struct {
	Name string
	Kind string // "store", "widget", "action", "variable", "model", "enum"
}

// EventRef represents a widget event referenced as "widgetName.eventName".
type EventRef struct {
	FullPath string
	Widget   string
	Event    string
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
