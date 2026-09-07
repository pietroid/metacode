package ir

import (
	"testing"
)

func TestParseAssertionShouldBe(t *testing.T) {
	assertion, ok, err := ParseAssertion("counterStore.value should be 6")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !ok {
		t.Fatal("expected assertion to be present")
	}
	if assertion.Target != "counterStore.value" {
		t.Errorf("expected target counterStore.value, got %q", assertion.Target)
	}
	if assertion.Op != "should be" {
		t.Errorf("expected op should be, got %q", assertion.Op)
	}
	if assertion.Value != "6" {
		t.Errorf("expected value 6, got %q", assertion.Value)
	}
}

func TestParseAssertionIs(t *testing.T) {
	assertion, ok, err := ParseAssertion("counterStore.value is 0")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !ok {
		t.Fatal("expected assertion to be present")
	}
	if assertion.Op != "is" {
		t.Errorf("expected op is, got %q", assertion.Op)
	}
}

func TestParseAssertionEquals(t *testing.T) {
	assertion, ok, err := ParseAssertion("homePage.counterValue = 5")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !ok {
		t.Fatal("expected assertion to be present")
	}
	if assertion.Target != "homePage.counterValue" {
		t.Errorf("expected target homePage.counterValue, got %q", assertion.Target)
	}
	if assertion.Op != "=" {
		t.Errorf("expected op =, got %q", assertion.Op)
	}
	if assertion.Value != "5" {
		t.Errorf("expected value 5, got %q", assertion.Value)
	}
}

func TestParseAssertionEmpty(t *testing.T) {
	assertion, ok, err := ParseAssertion("   ")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if ok {
		t.Error("expected empty assertion to be absent")
	}
	if assertion != nil {
		t.Error("expected nil assertion for empty string")
	}
}

func TestParseAssertionMalformed(t *testing.T) {
	_, _, err := ParseAssertion("counterStore.value")
	if err == nil {
		t.Fatal("expected error for malformed assertion")
	}
}

func TestParseBehaviorScenario(t *testing.T) {
	scenario, err := ParseBehaviorScenario(
		"counterStore/increments from 0",
		"increments from 0",
		[]string{"counterStore"},
		"counterStore.value is 0",
		"counterButton.onPressed",
		"counterStore.value should be 1",
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if scenario.ID != "counterStore/increments from 0" {
		t.Errorf("unexpected id: %q", scenario.ID)
	}
	if scenario.When != "counterButton.onPressed" {
		t.Errorf("unexpected when: %q", scenario.When)
	}
	if scenario.Given == nil || scenario.Given.Value != "0" {
		t.Errorf("unexpected given: %+v", scenario.Given)
	}
	if scenario.Then == nil || scenario.Then.Value != "1" {
		t.Errorf("unexpected then: %+v", scenario.Then)
	}
}

func TestParseBehaviorScenarioMissingThen(t *testing.T) {
	_, err := ParseBehaviorScenario("id", "desc", nil, "", "", "")
	if err == nil {
		t.Fatal("expected error for missing then")
	}
}

func TestParseBehaviorScenarioPureRendering(t *testing.T) {
	scenario, err := ParseBehaviorScenario(
		"render",
		"renders",
		nil,
		"",
		"",
		"homePage.counterValue = 5",
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if scenario.Given != nil {
		t.Errorf("expected nil given, got %+v", scenario.Given)
	}
	if scenario.When != "" {
		t.Errorf("expected empty when, got %q", scenario.When)
	}
	if scenario.Then == nil {
		t.Fatal("expected then assertion")
	}
}
