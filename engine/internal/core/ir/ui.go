package ir

// UIComponent represents a declared widget from ui.yaml.
type UIComponent struct {
	Name      string
	Kind      string // catalog symbol or "custom"
	Props     map[string]any
	Children  []UIComponent
	Variables []string // bare unknown names discovered in this subtree
}
