package spec

import (
	"os"
	"path/filepath"
	"testing"
)

func TestDiscoverSuccess(t *testing.T) {
	dir := t.TempDir()
	metacodeDir := filepath.Join(dir, "metacode")
	if err := os.MkdirAll(metacodeDir, 0755); err != nil {
		t.Fatalf("create metacode dir: %v", err)
	}
	for _, name := range []string{"project.yaml", "data.yaml", "ui.yaml", "behaviors.yaml"} {
		if err := os.WriteFile(filepath.Join(metacodeDir, name), []byte("{}"), 0644); err != nil {
			t.Fatalf("write %s: %v", name, err)
		}
	}

	paths, err := Discover(dir)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if paths.Root != dir {
		t.Errorf("expected root %q, got %q", dir, paths.Root)
	}
	if paths.Metacode != metacodeDir {
		t.Errorf("expected metacode dir %q, got %q", metacodeDir, paths.Metacode)
	}
	if paths.Project != filepath.Join(metacodeDir, "project.yaml") {
		t.Errorf("unexpected project path: %q", paths.Project)
	}
}

func TestDiscoverMissingFolder(t *testing.T) {
	dir := t.TempDir()
	_, err := Discover(dir)
	if err == nil {
		t.Fatal("expected error for missing metacode folder")
	}
	if !contains(err.Error(), "no metacode/ folder found") {
		t.Errorf("unexpected error message: %v", err)
	}
}

func TestDiscoverMissingFile(t *testing.T) {
	dir := t.TempDir()
	metacodeDir := filepath.Join(dir, "metacode")
	if err := os.MkdirAll(metacodeDir, 0755); err != nil {
		t.Fatalf("create metacode dir: %v", err)
	}
	for _, name := range []string{"project.yaml", "data.yaml", "behaviors.yaml"} {
		if err := os.WriteFile(filepath.Join(metacodeDir, name), []byte("{}"), 0644); err != nil {
			t.Fatalf("write %s: %v", name, err)
		}
	}

	_, err := Discover(dir)
	if err == nil {
		t.Fatal("expected error for missing ui.yaml")
	}
	if !contains(err.Error(), "ui.yaml") {
		t.Errorf("expected error to name ui.yaml, got: %v", err)
	}
}

func TestDiscoverWalksUpward(t *testing.T) {
	dir := t.TempDir()
	metacodeDir := filepath.Join(dir, "metacode")
	if err := os.MkdirAll(metacodeDir, 0755); err != nil {
		t.Fatalf("create metacode dir: %v", err)
	}
	for _, name := range []string{"project.yaml", "data.yaml", "ui.yaml", "behaviors.yaml"} {
		if err := os.WriteFile(filepath.Join(metacodeDir, name), []byte("{}"), 0644); err != nil {
			t.Fatalf("write %s: %v", name, err)
		}
	}
	nestedDir := filepath.Join(dir, "a", "b", "c")
	if err := os.MkdirAll(nestedDir, 0755); err != nil {
		t.Fatalf("create nested dir: %v", err)
	}

	paths, err := Discover(nestedDir)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if paths.Root != dir {
		t.Errorf("expected root %q, got %q", dir, paths.Root)
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsHelper(s, substr))
}

func containsHelper(s, substr string) bool {
	for i := 0; i+len(substr) <= len(s); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
