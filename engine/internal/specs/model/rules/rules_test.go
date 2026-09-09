package modelrules

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
)

func TestBuildReadsModelsAndEnums(t *testing.T) {
	raw := map[string]any{
		"task": map[string]any{
			"description": "string",
			"date":        "datetime?",
			"done":        "boolean",
		},
		"priority": []any{"low", "high"},
	}
	models, enums, err := Build(raw)
	if err != nil {
		t.Fatalf("build: %v", err)
	}
	if len(models) != 1 || models[0].Name != "task" {
		t.Fatalf("unexpected models: %+v", models)
	}
	date, ok := models[0].Field("date")
	if !ok || !date.Optional || date.Type != "datetime" {
		t.Errorf("expected an optional datetime, got %+v", date)
	}
	if len(enums) != 1 || len(enums[0].Values) != 2 {
		t.Errorf("unexpected enums: %+v", enums)
	}
}

func TestValidateRejectsAnUnknownFieldType(t *testing.T) {
	models := []model.Model{{Name: "task", Fields: []model.Field{{Name: "owner", Type: "user"}}}}
	if errs := Validate(models, nil); len(errs) != 1 {
		t.Fatalf("expected 1 error, got %v", errs)
	}
}

func TestValidateAcceptsAListOfADeclaredModel(t *testing.T) {
	models := []model.Model{
		{Name: "user", Fields: []model.Field{{Name: "name", Type: "string"}}},
		{Name: "team", Fields: []model.Field{{Name: "members", Type: "list(user)"}}},
	}
	if errs := Validate(models, nil); len(errs) != 0 {
		t.Fatalf("expected no errors, got %v", errs)
	}
}
