package uirules

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
)

func TestItemBuilders(t *testing.T) {
	comp := model.UIComponent{
		Name:  "defaultState",
		Kind:  "column",
		Props: map[string]any{},
		Children: []model.UIComponent{
			{Name: "listView", Kind: "listView", Props: map[string]any{"items": "taskList", "item": "taskTile"}},
		},
	}
	got := ItemBuilders(comp)
	if len(got) != 1 || got[0] != "taskTile" {
		t.Errorf("expected [taskTile], got %v", got)
	}
}
