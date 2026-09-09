package catalog

// Catalog provides lookup for the vocabularies the UI spec draws on: the widget
// symbols, and the icons a widget can name.
type Catalog struct {
	symbols map[string]Symbol
	icons   map[string]Icon
}

// defaultCatalog is the shared catalog. The vocabulary is fixed at compile time
// and a Catalog is read-only, so one instance serves every caller. The rules
// package consults it once per YAML node, which is why it is not rebuilt there.
var defaultCatalog = New()

// Default returns the shared catalog of common UI symbols.
func Default() *Catalog { return defaultCatalog }

// New returns a catalog populated with the default vocabularies.
func New() *Catalog {
	c := &Catalog{
		symbols: make(map[string]Symbol, len(defaultSymbols)),
		icons:   make(map[string]Icon, len(defaultIcons)),
	}
	for _, s := range defaultSymbols {
		c.symbols[s.Name] = s
	}
	for _, i := range defaultIcons {
		c.icons[i.Name] = i
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

// AllowsProp reports whether prop is a prop of the given widget at all, its
// default content prop included. It returns false if the symbol is unknown.
func (c *Catalog) AllowsProp(widget, prop string) bool {
	s, ok := c.symbols[widget]
	if !ok {
		return false
	}
	if prop == s.DefaultProp {
		return true
	}
	_, ok = s.Prop(prop)
	return ok
}

// Prop returns the declared prop and whether the symbol has it.
func (s Symbol) Prop(name string) (Prop, bool) {
	for _, p := range s.Props {
		if p.Name == name {
			return p, true
		}
	}
	return Prop{}, false
}

// PropType returns what a prop of the given widget holds. An unknown widget or
// prop reports TypeAny, which is what a generator falls back to.
func (c *Catalog) PropType(widget, prop string) PropType {
	s, ok := c.symbols[widget]
	if !ok {
		return TypeAny
	}
	p, ok := s.Prop(prop)
	if !ok {
		return TypeAny
	}
	return p.Type
}

// WidgetProp reports whether prop on the given widget expects a Widget value.
// It returns false if the symbol is unknown.
func (c *Catalog) WidgetProp(widget, prop string) bool {
	s, ok := c.symbols[widget]
	if !ok {
		return false
	}
	p, ok := s.Prop(prop)
	return ok && p.Type.IsWidget()
}
