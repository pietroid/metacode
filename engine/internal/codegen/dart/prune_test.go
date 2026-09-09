package dart

import (
	"os"
	"path/filepath"
	"testing"
)

func write(t *testing.T, root, rel, content string) string {
	t.Helper()
	path := filepath.Join(root, filepath.FromSlash(rel))
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatalf("write %s: %v", rel, err)
	}
	return path
}

const generatedHeader = "// " + Marker + " - DO NOT EDIT BY HAND\nclass A {}\n"

// TestPruneRemovesOnlyStaleGeneratedFiles is the regression test for output
// that outlived its spec. Generation only ever wrote files, so renaming a
// widget left the old widget, its wrapper, and its tests on disk. The stale
// tests kept running and kept failing, and one rename produced a list of
// failures for scenarios that no longer existed.
func TestPruneRemovesOnlyStaleGeneratedFiles(t *testing.T) {
	root := t.TempDir()

	write(t, root, "lib/widgets/increment_button.dart", generatedHeader)
	write(t, root, "lib/widgets/counter_button.dart", generatedHeader) // stale
	write(t, root, "test/increments_from_0_test.dart", generatedHeader)
	write(t, root, "test/counterStore_increments_from_0_test.dart", generatedHeader) // stale
	handWritten := write(t, root, "lib/widgets/my_own_widget.dart", "class Mine {}\n")

	expected := map[string]bool{
		"lib/widgets/increment_button.dart": true,
		"test/increments_from_0_test.dart":  true,
	}

	removed, err := Prune(root, []string{"lib/widgets", "test"}, expected)
	if err != nil {
		t.Fatalf("prune: %v", err)
	}

	want := []string{
		"lib/widgets/counter_button.dart",
		"test/counterStore_increments_from_0_test.dart",
	}
	if len(removed) != len(want) {
		t.Fatalf("removed %v, want %v", removed, want)
	}
	for i := range want {
		if removed[i] != want[i] {
			t.Errorf("removed[%d] = %q, want %q", i, removed[i], want[i])
		}
	}

	// A file this engine did not write is not this engine's to delete, even
	// when it sits in a generated directory and nothing expects it.
	if _, err := os.Stat(handWritten); err != nil {
		t.Errorf("expected the hand-written file to survive: %v", err)
	}
	for rel := range expected {
		if _, err := os.Stat(filepath.Join(root, filepath.FromSlash(rel))); err != nil {
			t.Errorf("expected %s to survive: %v", rel, err)
		}
	}
}

// TestPruneIgnoresMissingDirectories keeps a first run, before any output
// exists, from failing.
func TestPruneIgnoresMissingDirectories(t *testing.T) {
	removed, err := Prune(t.TempDir(), []string{"lib/wrappers"}, nil)
	if err != nil {
		t.Fatalf("prune: %v", err)
	}
	if len(removed) != 0 {
		t.Errorf("expected nothing removed, got %v", removed)
	}
}
