// Package catalog encodes the common UI vocabulary used by the Metacode engine.
//
// It is intentionally hard-coded for the MVP. Each catalog entry maps a spec
// symbol to its Flutter widget equivalent, the default content prop, the
// supported functional/layout props, and which of those props expect a Widget.
package catalog

// Common prop names reused across multiple catalog entries.
const (
	PropChild     = "child"
	PropChildren  = "children"
	PropTitle     = "title"
	PropIcon      = "icon"
	PropData      = "data"
	PropImage     = "image"
	PropContent   = "content"
	PropBody      = "body"
	PropActions   = "actions"
	PropLeading   = "leading"
	PropSubtitle  = "subtitle"
	PropTrailing  = "trailing"
	PropAppBar    = "appBar"
	PropFAB       = "floatingActionButton"
	PropBottomNav = "bottomNavigationBar"
	PropDrawer    = "drawer"
)

// Symbol describes a single entry in the UI catalog.
type Symbol struct {
	Name          string
	FlutterWidget string
	DefaultProp   string // canonical content prop (child, children, title, data, etc.)
	AllowedProps  []string
	WidgetProps   []string // props that expect a Widget or List<Widget>
}

// defaultSymbols is the hard-coded catalog synchronized with
// specification/base_specs/ui_catalog.md.
var defaultSymbols = []Symbol{
	{
		Name:          "appBar",
		FlutterWidget: "AppBar",
		DefaultProp:   PropTitle,
		AllowedProps:  []string{PropTitle, PropActions, PropLeading},
		WidgetProps:   []string{PropTitle, PropActions, PropLeading},
	},
	{
		Name:          "scaffold",
		FlutterWidget: "Scaffold",
		DefaultProp:   PropBody,
		AllowedProps:  []string{PropAppBar, PropBody, PropFAB, PropBottomNav, PropDrawer},
		WidgetProps:   []string{PropAppBar, PropBody, PropFAB, PropBottomNav, PropDrawer},
	},
	{
		Name:          "text",
		FlutterWidget: "Text",
		DefaultProp:   PropData,
		AllowedProps:  []string{PropData},
		WidgetProps:   nil,
	},
	{
		Name:          "elevatedButton",
		FlutterWidget: "ElevatedButton",
		DefaultProp:   PropChild,
		AllowedProps:  []string{PropChild, "onPressed"},
		WidgetProps:   []string{PropChild},
	},
	{
		Name:          "textButton",
		FlutterWidget: "TextButton",
		DefaultProp:   PropChild,
		AllowedProps:  []string{PropChild, "onPressed"},
		WidgetProps:   []string{PropChild},
	},
	{
		Name:          "iconButton",
		FlutterWidget: "IconButton",
		DefaultProp:   PropIcon,
		AllowedProps:  []string{PropIcon, "onPressed", "tooltip"},
		WidgetProps:   []string{PropIcon},
	},
	{
		Name:          "floatingActionButton",
		FlutterWidget: "FloatingActionButton",
		DefaultProp:   PropChild,
		AllowedProps:  []string{PropChild, "onPressed", "tooltip"},
		WidgetProps:   []string{PropChild},
	},
	{
		Name:          "card",
		FlutterWidget: "Card",
		DefaultProp:   PropChild,
		AllowedProps:  []string{PropChild},
		WidgetProps:   []string{PropChild},
	},
	{
		Name:          "listTile",
		FlutterWidget: "ListTile",
		DefaultProp:   PropTitle,
		AllowedProps:  []string{PropTitle, PropLeading, PropSubtitle, PropTrailing, "onTap"},
		WidgetProps:   []string{PropTitle, PropLeading, PropSubtitle, PropTrailing},
	},
	{
		Name:          "listView",
		FlutterWidget: "ListView",
		DefaultProp:   PropChildren,
		AllowedProps:  []string{PropChildren, "scrollDirection", "shrinkWrap", "itemBuilder", "itemCount"},
		WidgetProps:   []string{PropChildren, "itemBuilder"},
	},
	{
		Name:          "column",
		FlutterWidget: "Column",
		DefaultProp:   PropChildren,
		AllowedProps:  []string{PropChildren, "mainAxisAlignment", "crossAxisAlignment"},
		WidgetProps:   []string{PropChildren},
	},
	{
		Name:          "row",
		FlutterWidget: "Row",
		DefaultProp:   PropChildren,
		AllowedProps:  []string{PropChildren, "mainAxisAlignment", "crossAxisAlignment"},
		WidgetProps:   []string{PropChildren},
	},
	{
		Name:          "stack",
		FlutterWidget: "Stack",
		DefaultProp:   PropChildren,
		AllowedProps:  []string{PropChildren, "alignment"},
		WidgetProps:   []string{PropChildren},
	},
	{
		Name:          "container",
		FlutterWidget: "Container",
		DefaultProp:   PropChild,
		AllowedProps:  []string{PropChild, "width", "height", "padding", "margin"},
		WidgetProps:   []string{PropChild},
	},
	{
		Name:          "padding",
		FlutterWidget: "Padding",
		DefaultProp:   PropChild,
		AllowedProps:  []string{PropChild, "padding"},
		WidgetProps:   []string{PropChild},
	},
	{
		Name:          "center",
		FlutterWidget: "Center",
		DefaultProp:   PropChild,
		AllowedProps:  []string{PropChild},
		WidgetProps:   []string{PropChild},
	},
	{
		Name:          "sizedBox",
		FlutterWidget: "SizedBox",
		DefaultProp:   PropChild,
		AllowedProps:  []string{PropChild, "width", "height"},
		WidgetProps:   []string{PropChild},
	},
	{
		Name:          "expanded",
		FlutterWidget: "Expanded",
		DefaultProp:   PropChild,
		AllowedProps:  []string{PropChild, "flex"},
		WidgetProps:   []string{PropChild},
	},
	{
		Name:          "icon",
		FlutterWidget: "Icon",
		DefaultProp:   PropIcon,
		AllowedProps:  []string{PropIcon, "size", "color"},
		WidgetProps:   nil,
	},
	{
		Name:          "image",
		FlutterWidget: "Image",
		DefaultProp:   "src",
		AllowedProps:  []string{"src", "image", "width", "height", "fit"},
		WidgetProps:   nil,
	},
	{
		Name:          "textField",
		FlutterWidget: "TextField",
		DefaultProp:   "",
		AllowedProps:  []string{"controller", "onChanged", "decoration", "obscureText", "keyboardType"},
		WidgetProps:   nil,
	},
	{
		Name:          "checkbox",
		FlutterWidget: "Checkbox",
		DefaultProp:   "",
		AllowedProps:  []string{"value", "onChanged"},
		WidgetProps:   nil,
	},
	{
		Name:          "radio",
		FlutterWidget: "Radio",
		DefaultProp:   "",
		AllowedProps:  []string{"value", "groupValue", "onChanged"},
		WidgetProps:   nil,
	},
	{
		Name:          "switch",
		FlutterWidget: "Switch",
		DefaultProp:   "",
		AllowedProps:  []string{"value", "onChanged"},
		WidgetProps:   nil,
	},
	{
		Name:          "slider",
		FlutterWidget: "Slider",
		DefaultProp:   "",
		AllowedProps:  []string{"value", "min", "max", "onChanged"},
		WidgetProps:   nil,
	},
	{
		Name:          "dropdownButton",
		FlutterWidget: "DropdownButton",
		DefaultProp:   "",
		AllowedProps:  []string{"value", "items", "onChanged", "hint"},
		WidgetProps:   nil,
	},
	{
		Name:          "bottomNavigationBar",
		FlutterWidget: "BottomNavigationBar",
		DefaultProp:   "",
		AllowedProps:  []string{"currentIndex", "onTap", "items"},
		WidgetProps:   nil,
	},
	{
		Name:          "tabBar",
		FlutterWidget: "TabBar",
		DefaultProp:   "",
		AllowedProps:  []string{"tabs", "controller"},
		WidgetProps:   nil,
	},
	{
		Name:          "alertDialog",
		FlutterWidget: "AlertDialog",
		DefaultProp:   PropContent,
		AllowedProps:  []string{PropContent, PropTitle, PropActions},
		WidgetProps:   []string{PropContent, PropTitle, PropActions},
	},
	{
		Name:          "circularProgressIndicator",
		FlutterWidget: "CircularProgressIndicator",
		DefaultProp:   "",
		AllowedProps:  []string{"value"},
		WidgetProps:   nil,
	},
}
