package ir

// SymbolTable registers all declared symbols and their kinds.
type SymbolTable struct {
	Symbols   map[string]Symbol
	Stores    map[string]Store
	Widgets   map[string]UIComponent
	Actions   map[string]ActionRef
	Events    map[string]EventRef
	Variables map[string]VariableRef
}

// Symbol is a named entity referenced by the specs.
type Symbol struct {
	Name string
	Kind string // "store", "widget", "action", "variable", "model", "enum"
}

// ActionRef represents a store action referenced as "storeName.actionName".
type ActionRef struct {
	FullPath string
	Store    string
	Name     string
}

// EventRef represents a widget event referenced as "widgetName.eventName".
type EventRef struct {
	FullPath string
	Widget   string
	Event    string
}

// VariableRef represents a bare unknown name discovered in the UI tree.
type VariableRef struct {
	Name string
}

// NewSymbolTable creates an empty symbol table.
func NewSymbolTable() SymbolTable {
	return SymbolTable{
		Symbols:   make(map[string]Symbol),
		Stores:    make(map[string]Store),
		Widgets:   make(map[string]UIComponent),
		Actions:   make(map[string]ActionRef),
		Events:    make(map[string]EventRef),
		Variables: make(map[string]VariableRef),
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
