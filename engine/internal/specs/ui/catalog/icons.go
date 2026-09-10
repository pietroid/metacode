// Icons are a vocabulary in their own right, kept beside the widget catalog for
// the same reason: the spec names a thing, and the entry says what that name
// becomes in the target language. Repeating a name that happens to match
// Material's is the point. Metacode owns its spelling, so `icons.hidden` can
// stay `icons.hidden` when a second target calls it something else.
package catalog

import "strings"

// IconPrefix qualifies an icon value. A bare name under an `icon` prop is a
// variable like anywhere else in the spec; `icons.add` is a value from this
// vocabulary.
const IconPrefix = "icons."

// Icon is one entry of the icon vocabulary.
type Icon struct {
	Name        string // what the spec writes after `icons.`
	FlutterIcon string // what the Flutter target generates
}

// defaultIcons is the hard-coded icon vocabulary, synchronized with
// docs/language/catalog.md.
var defaultIcons = []Icon{
	{"add", "Icons.add"},
	{"remove", "Icons.remove"},
	{"close", "Icons.close"},
	{"check", "Icons.check"},
	{"success", "Icons.check_circle"},
	{"cancel", "Icons.cancel"},
	{"edit", "Icons.edit"},
	{"delete", "Icons.delete"},
	{"save", "Icons.save"},
	{"copy", "Icons.content_copy"},
	{"send", "Icons.send"},
	{"share", "Icons.share"},
	{"search", "Icons.search"},
	{"filter", "Icons.filter_list"},
	{"sort", "Icons.sort"},
	{"refresh", "Icons.refresh"},
	{"menu", "Icons.menu"},
	{"home", "Icons.home"},
	{"settings", "Icons.settings"},
	{"person", "Icons.person"},
	{"login", "Icons.login"},
	{"logout", "Icons.logout"},
	{"lock", "Icons.lock"},
	{"favorite", "Icons.favorite"},
	{"star", "Icons.star"},
	{"visible", "Icons.visibility"},
	{"hidden", "Icons.visibility_off"},
	{"notification", "Icons.notifications"},
	{"mail", "Icons.mail"},
	{"phone", "Icons.phone"},
	{"camera", "Icons.camera_alt"},
	{"image", "Icons.image"},
	{"attachment", "Icons.attach_file"},
	{"download", "Icons.download"},
	{"upload", "Icons.upload"},
	{"calendar", "Icons.calendar_today"},
	{"clock", "Icons.access_time"},
	{"location", "Icons.location_on"},
	{"cart", "Icons.shopping_cart"},
	{"play", "Icons.play_arrow"},
	{"pause", "Icons.pause"},
	{"stop", "Icons.stop"},
	{"warning", "Icons.warning"},
	{"error", "Icons.error"},
	{"info", "Icons.info"},
	{"help", "Icons.help"},
	{"arrowBack", "Icons.arrow_back"},
	{"arrowForward", "Icons.arrow_forward"},
	{"arrowUp", "Icons.arrow_upward"},
	{"arrowDown", "Icons.arrow_downward"},
	{"chevronLeft", "Icons.chevron_left"},
	{"chevronRight", "Icons.chevron_right"},
	{"moreVertical", "Icons.more_vert"},
	{"moreHorizontal", "Icons.more_horiz"},
}

// IsIconRef reports whether a spec value is qualified as an icon.
func IsIconRef(value string) bool {
	return strings.HasPrefix(value, IconPrefix)
}

// FindIcon returns the icon a qualified value names, and whether the vocabulary
// has it. An unqualified value is never an icon.
func (c *Catalog) FindIcon(value string) (Icon, bool) {
	if !IsIconRef(value) {
		return Icon{}, false
	}
	icon, ok := c.icons[strings.TrimPrefix(value, IconPrefix)]
	return icon, ok
}
