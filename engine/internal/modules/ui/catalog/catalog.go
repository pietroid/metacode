package catalog

// Catalog provides lookup for the common UI widget vocabulary.
type Catalog struct {
	symbols map[string]Symbol
}

// New returns a catalog populated with the default common UI symbols.
func New() *Catalog {
	c := &Catalog{symbols: make(map[string]Symbol, len(defaultSymbols))}
	for _, s := range defaultSymbols {
		c.symbols[s.Name] = s
	}
	return c
}

// Find returns the catalog symbol for name and whether it was found.
func (c *Catalog) Find(name string) (Symbol, bool) {
	s, ok := c.symbols[name]
	return s, ok
}

// IsKnown reports whether name is a catalog widget symbol.
func (c *Catalog) IsKnown(name string) bool {
	_, ok := c.symbols[name]
	return ok
}

// Names returns all known symbol names. The order is unspecified.
func (c *Catalog) Names() []string {
	names := make([]string, 0, len(c.symbols))
	for name := range c.symbols {
		names = append(names, name)
	}
	return names
}

// WidgetProp reports whether prop on the given widget expects a Widget value.
// It returns false if the symbol is unknown.
func (c *Catalog) WidgetProp(widget, prop string) bool {
	s, ok := c.symbols[widget]
	if !ok {
		return false
	}
	for _, p := range s.WidgetProps {
		if p == prop {
			return true
		}
	}
	return false
}
