package model

// RouteType is how a destination appears on screen.
//
// It is a property of the route rather than of the widget it shows, which is
// what keeps `bottomSheet` out of every other spec: a widget is a widget, and
// the same one can be a page in one project and a sheet in another. A behavior
// says the app moved to a route and never says how the route looks.
type RouteType string

// The presentation kinds a route may declare.
const (
	RoutePage        RouteType = "page"
	RouteBottomSheet RouteType = "bottomSheet"
	RouteDialog      RouteType = "dialog"
)

// IsModal reports whether a route is shown over what is already on screen
// rather than replacing it. A modal route leaves the page beneath it built,
// which is why a sheet can read the same store the page was reading.
func (t RouteType) IsModal() bool {
	return t == RouteBottomSheet || t == RouteDialog
}

// Route is one destination declared in navigation.yaml.
type Route struct {
	Name  string
	Child string // the widget symbol this route shows
	Type  RouteType
}

// Navigation is the route table.
//
// A project without navigation.yaml has none, and its single page is found the
// way it always was: the first page in the UI spec. Declaring routes is what
// turns the generated app into a routed one.
type Navigation struct {
	InitialRoute string
	Routes       []Route
}

// Declared reports whether the project has a route table at all.
func (n Navigation) Declared() bool { return len(n.Routes) > 0 }

// Route returns the route with the given name.
func (n Navigation) Route(name string) (Route, bool) {
	for _, r := range n.Routes {
		if r.Name == name {
			return r, true
		}
	}
	return Route{}, false
}

// Initial returns the route the app opens on.
func (n Navigation) Initial() (Route, bool) { return n.Route(n.InitialRoute) }

// Uses reports whether any route is presented the given way, which is what
// decides whether the generated router needs the Page class for it.
func (n Navigation) Uses(t RouteType) bool {
	for _, r := range n.Routes {
		if r.Type == t {
			return true
		}
	}
	return false
}
