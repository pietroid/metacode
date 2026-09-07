package catalog

import (
	"slices"
	"testing"
)

func TestFindKnownWidgets(t *testing.T) {
	c := New()

	text, ok := c.Find("text")
	if !ok {
		t.Fatal("expected text to be found")
	}
	if text.FlutterWidget != "Text" {
		t.Errorf("expected Flutter widget Text, got %q", text.FlutterWidget)
	}
	if text.DefaultProp != PropData {
		t.Errorf("expected default prop data, got %q", text.DefaultProp)
	}

	col, ok := c.Find("column")
	if !ok {
		t.Fatal("expected column to be found")
	}
	if col.FlutterWidget != "Column" || col.DefaultProp != PropChildren {
		t.Errorf("unexpected column entry: %+v", col)
	}
}

func TestFindUnknownWidget(t *testing.T) {
	c := New()
	_, ok := c.Find("unknownWidget")
	if ok {
		t.Error("expected unknownWidget to be unknown")
	}
	if c.IsKnown("unknownWidget") {
		t.Error("expected IsKnown to return false for unknownWidget")
	}
}

// expectedSymbols is the first column of the UI catalog table in
// specification/base_specs/ui_catalog.md. Keeping this list in the test makes
// the catalog<->spec coupling explicit and fail loudly if they drift.
var expectedSymbols = []string{
	"appBar",
	"scaffold",
	"text",
	"elevatedButton",
	"textButton",
	"iconButton",
	"floatingActionButton",
	"card",
	"listTile",
	"listView",
	"column",
	"row",
	"stack",
	"container",
	"padding",
	"center",
	"sizedBox",
	"expanded",
	"icon",
	"image",
	"textField",
	"checkbox",
	"radio",
	"switch",
	"slider",
	"dropdownButton",
	"bottomNavigationBar",
	"tabBar",
	"alertDialog",
	"circularProgressIndicator",
}

func TestCatalogContainsAllSpecSymbols(t *testing.T) {
	c := New()
	missing := []string{}
	for _, name := range expectedSymbols {
		if !c.IsKnown(name) {
			missing = append(missing, name)
		}
	}
	if len(missing) > 0 {
		t.Errorf("catalog is missing symbols from ui_catalog.md: %v", missing)
	}

	extra := []string{}
	for _, name := range c.Names() {
		if !slices.Contains(expectedSymbols, name) {
			extra = append(extra, name)
		}
	}
	if len(extra) > 0 {
		t.Errorf("catalog has symbols not in ui_catalog.md: %v", extra)
	}
}

func TestWidgetProp(t *testing.T) {
	c := New()
	if !c.WidgetProp("scaffold", "body") {
		t.Error("expected scaffold.body to be a widget prop")
	}
	if !c.WidgetProp("appBar", "title") {
		t.Error("expected appBar.title to be a widget prop")
	}
	if c.WidgetProp("text", "data") {
		t.Error("expected text.data to be a string prop")
	}
}
