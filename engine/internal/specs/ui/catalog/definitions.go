// Package catalog encodes the common UI vocabulary used by the Metacode engine.
//
// It is intentionally hard-coded for the MVP. Each catalog entry maps a spec
// symbol to its target widget, its default content prop, and every prop it
// takes with the kind of thing that prop holds. The prop type is what tells a
// generator that `value: taskDone` on a checkbox is a boolean and
// `onChanged: taskToggled` is a callback, rather than guessing that every
// unknown name is a string.
package catalog

// Common prop names reused across multiple catalog entries.
const (
	PropChild     = "child"
	PropChildren  = "children"
	PropTitle     = "title"
	PropIcon      = "icon"
	PropItems     = "items"
	PropItem      = "item"
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

// PropType is what a prop holds, in Metacode's own words. A target maps these
// to its own types; nothing here names Dart.
type PropType string

const (
	TypeWidget          PropType = "widget"
	TypeWidgets         PropType = "widgets"
	TypeText            PropType = "text"
	TypeBoolean         PropType = "boolean"
	TypeNumber          PropType = "number"
	TypeList            PropType = "list"
	TypeIcon            PropType = "icon"
	TypeAny             PropType = "any"
	TypeCallback        PropType = "callback"
	TypeCallbackText    PropType = "callback(text)"
	TypeCallbackBoolean PropType = "callback(boolean)"
	TypeCallbackNumber  PropType = "callback(number)"
	TypeCallbackAny     PropType = "callback(any)"
)

// IsCallback reports whether a prop of this type holds an event handler rather
// than a value.
func (t PropType) IsCallback() bool {
	return t == TypeCallback || t == TypeCallbackText || t == TypeCallbackBoolean ||
		t == TypeCallbackNumber || t == TypeCallbackAny
}

// IsWidget reports whether a prop of this type holds a widget or a list of them.
func (t PropType) IsWidget() bool {
	return t == TypeWidget || t == TypeWidgets
}

// Prop is one prop of a catalog symbol. The order they are declared in is the
// order a generator writes them.
type Prop struct {
	Name string
	Type PropType
}

// Symbol describes a single entry in the UI catalog.
type Symbol struct {
	Name          string
	FlutterWidget string
	DefaultProp   string // canonical content prop (child, children, title, data, etc.)
	Props         []Prop
}

// defaultSymbols is the hard-coded catalog synchronized with
// docs/language/catalog.md.
var defaultSymbols = []Symbol{
	{
		Name:          "appBar",
		FlutterWidget: "AppBar",
		DefaultProp:   PropTitle,
		Props: []Prop{
			{PropTitle, TypeWidget},
			{PropActions, TypeWidgets},
			{PropLeading, TypeWidget},
		},
	},
	{
		Name:          "scaffold",
		FlutterWidget: "Scaffold",
		DefaultProp:   PropBody,
		Props: []Prop{
			{PropBody, TypeWidget},
			{PropAppBar, TypeWidget},
			{PropFAB, TypeWidget},
			{PropBottomNav, TypeWidget},
			{PropDrawer, TypeWidget},
		},
	},
	{
		Name:          "text",
		FlutterWidget: "Text",
		DefaultProp:   PropData,
		Props: []Prop{
			{PropData, TypeText},
		},
	},
	{
		Name:          "elevatedButton",
		FlutterWidget: "ElevatedButton",
		DefaultProp:   PropChild,
		Props: []Prop{
			{PropChild, TypeWidget},
			{"onPressed", TypeCallback},
		},
	},
	{
		Name:          "textButton",
		FlutterWidget: "TextButton",
		DefaultProp:   PropChild,
		Props: []Prop{
			{PropChild, TypeWidget},
			{"onPressed", TypeCallback},
		},
	},
	{
		Name:          "iconButton",
		FlutterWidget: "IconButton",
		DefaultProp:   PropIcon,
		Props: []Prop{
			{PropIcon, TypeIcon},
			{"onPressed", TypeCallback},
			{"tooltip", TypeText},
		},
	},
	{
		Name:          "floatingActionButton",
		FlutterWidget: "FloatingActionButton",
		DefaultProp:   PropChild,
		Props: []Prop{
			{PropChild, TypeWidget},
			{"onPressed", TypeCallback},
			{"tooltip", TypeText},
		},
	},
	{
		Name:          "card",
		FlutterWidget: "Card",
		DefaultProp:   PropChild,
		Props: []Prop{
			{PropChild, TypeWidget},
		},
	},
	{
		Name:          "listTile",
		FlutterWidget: "ListTile",
		DefaultProp:   PropTitle,
		Props: []Prop{
			{PropTitle, TypeWidget},
			{PropLeading, TypeWidget},
			{PropSubtitle, TypeWidget},
			{PropTrailing, TypeWidget},
			{"onTap", TypeCallback},
		},
	},
	{
		Name:          "listView",
		FlutterWidget: "ListView",
		DefaultProp:   PropChildren,
		Props: []Prop{
			{PropChildren, TypeWidgets},
			{"scrollDirection", TypeText},
			{"shrinkWrap", TypeBoolean},
			{PropItems, TypeList},
			{PropItem, TypeWidget},
		},
	},
	{
		Name:          "column",
		FlutterWidget: "Column",
		DefaultProp:   PropChildren,
		Props: []Prop{
			{PropChildren, TypeWidgets},
			{"mainAxisAlignment", TypeText},
			{"crossAxisAlignment", TypeText},
		},
	},
	{
		Name:          "row",
		FlutterWidget: "Row",
		DefaultProp:   PropChildren,
		Props: []Prop{
			{PropChildren, TypeWidgets},
			{"mainAxisAlignment", TypeText},
			{"crossAxisAlignment", TypeText},
		},
	},
	{
		Name:          "stack",
		FlutterWidget: "Stack",
		DefaultProp:   PropChildren,
		Props: []Prop{
			{PropChildren, TypeWidgets},
			{"alignment", TypeText},
		},
	},
	{
		Name:          "container",
		FlutterWidget: "Container",
		DefaultProp:   PropChild,
		Props: []Prop{
			{PropChild, TypeWidget},
			{"width", TypeNumber},
			{"height", TypeNumber},
			{"padding", TypeNumber},
			{"margin", TypeNumber},
		},
	},
	{
		Name:          "padding",
		FlutterWidget: "Padding",
		DefaultProp:   PropChild,
		Props: []Prop{
			{PropChild, TypeWidget},
			{"padding", TypeNumber},
		},
	},
	{
		Name:          "center",
		FlutterWidget: "Center",
		DefaultProp:   PropChild,
		Props: []Prop{
			{PropChild, TypeWidget},
		},
	},
	{
		Name:          "sizedBox",
		FlutterWidget: "SizedBox",
		DefaultProp:   PropChild,
		Props: []Prop{
			{PropChild, TypeWidget},
			{"width", TypeNumber},
			{"height", TypeNumber},
		},
	},
	{
		Name:          "expanded",
		FlutterWidget: "Expanded",
		DefaultProp:   PropChild,
		Props: []Prop{
			{PropChild, TypeWidget},
			{"flex", TypeNumber},
		},
	},
	{
		Name:          "icon",
		FlutterWidget: "Icon",
		DefaultProp:   PropIcon,
		Props: []Prop{
			{PropIcon, TypeIcon},
			{"size", TypeNumber},
			{"color", TypeText},
		},
	},
	{
		Name:          "image",
		FlutterWidget: "Image",
		DefaultProp:   PropImage,
		Props: []Prop{
			{PropImage, TypeText},
			{"src", TypeText},
			{"width", TypeNumber},
			{"height", TypeNumber},
			{"fit", TypeText},
		},
	},
	{
		Name:          "textField",
		FlutterWidget: "TextField",
		Props: []Prop{
			{"controller", TypeAny},
			{"onChanged", TypeCallbackText},
			{"decoration", TypeAny},
			{"obscureText", TypeBoolean},
			{"keyboardType", TypeText},
		},
	},
	{
		Name:          "checkbox",
		FlutterWidget: "Checkbox",
		Props: []Prop{
			{"value", TypeBoolean},
			{"onChanged", TypeCallbackBoolean},
		},
	},
	{
		Name:          "radio",
		FlutterWidget: "Radio",
		Props: []Prop{
			{"value", TypeAny},
			{"groupValue", TypeAny},
			{"onChanged", TypeCallbackAny},
		},
	},
	{
		Name:          "switch",
		FlutterWidget: "Switch",
		Props: []Prop{
			{"value", TypeBoolean},
			{"onChanged", TypeCallbackBoolean},
		},
	},
	{
		Name:          "slider",
		FlutterWidget: "Slider",
		Props: []Prop{
			{"value", TypeNumber},
			{"min", TypeNumber},
			{"max", TypeNumber},
			{"onChanged", TypeCallbackNumber},
		},
	},
	{
		Name:          "dropdownButton",
		FlutterWidget: "DropdownButton",
		Props: []Prop{
			{"value", TypeAny},
			{PropItems, TypeList},
			{"onChanged", TypeCallbackAny},
			{"hint", TypeWidget},
		},
	},
	{
		Name:          "bottomNavigationBar",
		FlutterWidget: "BottomNavigationBar",
		Props: []Prop{
			{"currentIndex", TypeNumber},
			{"onTap", TypeCallbackNumber},
			{PropItems, TypeList},
		},
	},
	{
		Name:          "tabBar",
		FlutterWidget: "TabBar",
		Props: []Prop{
			{"tabs", TypeWidgets},
			{"controller", TypeAny},
		},
	},
	{
		Name:          "alertDialog",
		FlutterWidget: "AlertDialog",
		DefaultProp:   PropContent,
		Props: []Prop{
			{PropContent, TypeWidget},
			{PropTitle, TypeWidget},
			{PropActions, TypeWidgets},
		},
	},
	{
		Name:          "circularProgressIndicator",
		FlutterWidget: "CircularProgressIndicator",
		Props: []Prop{
			{"value", TypeNumber},
		},
	},
}
