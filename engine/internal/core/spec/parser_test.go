package spec

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseCounterSpecs(t *testing.T) {
	dir := t.TempDir()
	metacodeDir := filepath.Join(dir, "metacode")
	if err := os.MkdirAll(metacodeDir, 0755); err != nil {
		t.Fatalf("create metacode dir: %v", err)
	}

	writeFile(t, filepath.Join(metacodeDir, "project.yaml"), `
name: counter_app
description: A simple counter app
`)
	writeFile(t, filepath.Join(metacodeDir, "data.yaml"), `
stores:
  counter:
    type: int
    initial: 0
`)
	writeFile(t, filepath.Join(metacodeDir, "ui.yaml"), `
widgets:
  homePage:
    type: scaffold
`)
	writeFile(t, filepath.Join(metacodeDir, "behaviors.yaml"), `
counter:
  increments:
    given:
      counter.value: 0
    when: increment button is tapped
    then: counter becomes 1
`)

	paths, err := Discover(dir)
	if err != nil {
		t.Fatalf("discover: %v", err)
	}
	raw, err := Parse(paths)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}

	if raw.Project["name"] != "counter_app" {
		t.Errorf("expected project name counter_app, got %v", raw.Project["name"])
	}
	if _, ok := raw.Data["stores"]; !ok {
		t.Errorf("expected data to contain stores")
	}
	if _, ok := raw.UI["widgets"]; !ok {
		t.Errorf("expected ui to contain widgets")
	}
	if _, ok := raw.Behaviors["counter"]; !ok {
		t.Errorf("expected behaviors to contain counter")
	}
}

func TestParseInvalidYAML(t *testing.T) {
	dir := t.TempDir()
	metacodeDir := filepath.Join(dir, "metacode")
	if err := os.MkdirAll(metacodeDir, 0755); err != nil {
		t.Fatalf("create metacode dir: %v", err)
	}
	for _, name := range []string{"project.yaml", "data.yaml", "ui.yaml", "behaviors.yaml"} {
		writeFile(t, filepath.Join(metacodeDir, name), "valid: true")
	}
	writeFile(t, filepath.Join(metacodeDir, "ui.yaml"), "bad: [unclosed")

	paths, err := Discover(dir)
	if err != nil {
		t.Fatalf("discover: %v", err)
	}
	_, err = Parse(paths)
	if err == nil {
		t.Fatal("expected error for invalid YAML")
	}
	if !contains(err.Error(), "ui.yaml") {
		t.Errorf("expected error to mention ui.yaml, got: %v", err)
	}
}

func writeFile(t *testing.T, path, content string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}
