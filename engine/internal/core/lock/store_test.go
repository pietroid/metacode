package lock

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/spec"
)

// project writes a minimal metacode folder and returns its Paths.
func project(t *testing.T, behaviors string) spec.Paths {
	t.Helper()
	root := t.TempDir()
	dir := filepath.Join(root, "metacode")
	if err := os.MkdirAll(dir, 0755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	files := map[string]string{
		"project.yaml":   "name: counter_app\n",
		"data.yaml":      "stores:\n  counterStore:\n    value: int\n    initialValue: 0\n",
		"ui.yaml":        "widgets:\n  homePage:\n    scaffold:\n      body: counterValue\n",
		"behaviors.yaml": behaviors,
	}
	for name, content := range files {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(content), 0644); err != nil {
			t.Fatalf("write %s: %v", name, err)
		}
	}
	paths, err := spec.Discover(root)
	if err != nil {
		t.Fatalf("discover: %v", err)
	}
	return paths
}

func TestReadReportsNoLockBeforeAnyRun(t *testing.T) {
	paths := project(t, "counterStore: {}\n")

	if _, err := Read(paths); err != ErrNoLock {
		t.Fatalf("expected ErrNoLock, got %v", err)
	}
}

func TestWriteThenReadRoundTrips(t *testing.T) {
	paths := project(t, "counterStore:\n  increments: {when: 'counterStore.increment'}\n")

	if err := Write(paths, Stamp{RulesHash: "abc"}); err != nil {
		t.Fatalf("write: %v", err)
	}
	locked, err := Read(paths)
	if err != nil {
		t.Fatalf("read: %v", err)
	}
	if locked.Stamp.RulesHash != "abc" {
		t.Errorf("rules hash: got %q, want abc", locked.Stamp.RulesHash)
	}
	if len(locked.Specs.Behaviors) == 0 {
		t.Error("the lock lost behaviors.yaml")
	}
}

// TestWriteLeavesNoTemporaryDirectory is the visible half of the rename: an
// interrupted run must leave the previous lock rather than a mixture of two,
// which means the new one is never assembled in place.
func TestWriteLeavesNoTemporaryDirectory(t *testing.T) {
	paths := project(t, "counterStore: {}\n")

	if err := Write(paths, Stamp{}); err != nil {
		t.Fatalf("write: %v", err)
	}
	if _, err := os.Stat(filepath.Join(paths.Metacode, tmpDirName)); !os.IsNotExist(err) {
		t.Error("the temporary lock directory survived the write")
	}
}

// TestWriteReplacesTheWholeLock catches a lock that accumulates: a spec file
// deleted from the project has to disappear from the lock too, or the next
// diff compares against a store that no longer exists.
func TestWriteReplacesTheWholeLock(t *testing.T) {
	paths := project(t, "counterStore: {}\n")
	if err := Write(paths, Stamp{}); err != nil {
		t.Fatalf("write: %v", err)
	}
	stray := filepath.Join(Dir(paths), "models.yaml")
	if err := os.WriteFile(stray, []byte("models: {}\n"), 0644); err != nil {
		t.Fatalf("write stray: %v", err)
	}

	if err := Write(paths, Stamp{}); err != nil {
		t.Fatalf("rewrite: %v", err)
	}
	if _, err := os.Stat(stray); !os.IsNotExist(err) {
		t.Error("a file the project no longer has survived in the lock")
	}
}

// TestPartialLockIsNoLock keeps a half-written or hand-edited lock from being
// diffed against. Half of a previous state is not one.
func TestPartialLockIsNoLock(t *testing.T) {
	paths := project(t, "counterStore: {}\n")
	if err := Write(paths, Stamp{}); err != nil {
		t.Fatalf("write: %v", err)
	}
	if err := os.Remove(filepath.Join(Dir(paths), "ui.yaml")); err != nil {
		t.Fatalf("remove: %v", err)
	}

	if _, err := Read(paths); err != ErrNoLock {
		t.Fatalf("expected ErrNoLock, got %v", err)
	}
}

func TestHashRulesIsStableAndSensitive(t *testing.T) {
	if HashRules("a") != HashRules("a") {
		t.Error("the same rules hashed to two values")
	}
	if HashRules("a") == HashRules("b") {
		t.Error("different rules hashed to one value")
	}
}
