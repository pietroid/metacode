package ir

// SymbolTable registers all declared symbols and their kinds.
type SymbolTable struct {
	Symbols map[string]Symbol
}

// Symbol is a named entity referenced by the specs.
type Symbol struct {
	Name string
	Kind string // "store", "widget", "action", "variable", "model", "enum"
}

// NewSymbolTable creates an empty symbol table.
func NewSymbolTable() SymbolTable {
	return SymbolTable{Symbols: make(map[string]Symbol)}
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
