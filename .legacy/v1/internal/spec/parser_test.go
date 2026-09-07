package spec

import (
	"testing"

	"gopkg.in/yaml.v3"
)

const sampleYAML = `
counterStore:
    value: int
    initialValue: 0
    type: ephemeral

homePage:
    stack:
        - center:
            text:
                counterValue
        - aligned.bottomRight:
            counterButton

counterButton:
    button:
        label: "Add"

When button is tapped, increment counter:
    given:
    when: homePage.counterButton.onPressed
    then: counterStore.increment

When counter is incremented, increment the store:
    given: counterStore.value = 2
    when: counterStore.increment
    then: counterStore.value = 3

Show counter value on the home page:
    given: counterStore.value = 5
    when:
    then: homePage.counterValue = 5
`

func TestLoadSpecsFromBytes(t *testing.T) {
	set, err := loadSpecsFromString(sampleYAML)
	if err != nil {
		t.Fatalf("failed to parse sample: %v", err)
	}

	if len(set.DataStores) != 1 {
		t.Fatalf("expected 1 data store, got %d", len(set.DataStores))
	}
	store, ok := set.DataStores["counterStore"]
	if !ok {
		t.Fatalf("expected counterStore data spec")
	}
	if store.StorageType != "ephemeral" {
		t.Errorf("expected storage type ephemeral, got %s", store.StorageType)
	}
	if len(store.Fields) != 1 || store.Fields[0].Name != "value" {
		t.Errorf("expected single field named value, got %+v", store.Fields)
	}
	if store.Fields[0].InitialValue != "0" {
		t.Errorf("expected initialValue 0, got %s", store.Fields[0].InitialValue)
	}

	if len(set.UIWidgets) != 2 {
		t.Fatalf("expected 2 UI widgets, got %d", len(set.UIWidgets))
	}
	home := set.UIWidgets["homePage"]
	if home.Root.Kind != "stack" || len(home.Root.Children) != 2 {
		t.Errorf("homePage root should be a stack with 2 children, got %s/%d", home.Root.Kind, len(home.Root.Children))
	}
	btn := set.UIWidgets["counterButton"]
	if btn.Root.Kind != "button" {
		t.Errorf("counterButton root should be button, got %s", btn.Root.Kind)
	}
	if label, ok := btn.Root.Props["label"].(string); !ok || label != "Add" {
		t.Errorf("counterButton label should be Add, got %v", btn.Root.Props["label"])
	}

	if len(set.Tests) != 3 {
		t.Fatalf("expected 3 tests, got %d", len(set.Tests))
	}
	found := map[string]bool{}
	for _, test := range set.Tests {
		found[test.Name] = true
	}
	for _, want := range []string{
		"When button is tapped, increment counter",
		"When counter is incremented, increment the store",
		"Show counter value on the home page",
	} {
		if !found[want] {
			t.Errorf("missing test %q", want)
		}
	}
}

func loadSpecsFromString(s string) (*SpecSet, error) {
	var raw map[string]interface{}
	if err := yaml.Unmarshal([]byte(s), &raw); err != nil {
		return nil, err
	}
	set := &SpecSet{
		DataStores: map[string]*DataSpec{},
		UIWidgets:  map[string]*UISpec{},
	}
	for k, v := range raw {
		if err := ingestTopLevel(set, k, v); err != nil {
			return nil, err
		}
	}
	return set, nil
}
