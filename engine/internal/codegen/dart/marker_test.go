package dart

import (
	"os"
	"path/filepath"
	"testing"
)

func writeMarked(t *testing.T, content string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "file.dart")
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatalf("write: %v", err)
	}
	return path
}

// TestTheHeaderSaysWhoWroteIt is the second of the two signals the freeze set
// reads. The lock says what the author changed; this says whether a file has
// ever been implemented, which is the only thing that survives a deleted lib/
// or a fresh clone.
func TestTheHeaderSaysWhoWroteIt(t *testing.T) {
	for _, tc := range []struct {
		name                     string
		content                  string
		stub, implemented, prune bool
	}{
		{"scaffolded", StubHeader + "\nclass A {}\n", true, false, true},
		{"implemented", ImplementedHeader + "\nclass A {}\n", false, true, true},
		{"hand written", "class A {}\n", false, false, false},
		{"empty", "", false, false, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			path := writeMarked(t, tc.content)
			if got := IsStub(path); got != tc.stub {
				t.Errorf("IsStub: got %v, want %v", got, tc.stub)
			}
			if got := IsImplemented(path); got != tc.implemented {
				t.Errorf("IsImplemented: got %v, want %v", got, tc.implemented)
			}
			got, err := isGenerated(path)
			if err != nil {
				t.Fatalf("isGenerated: %v", err)
			}
			if got != tc.prune {
				t.Errorf("isGenerated: got %v, want %v", got, tc.prune)
			}
		})
	}
}

// TestAMissingFileIsNeither: there is nothing there to preserve, so a caller
// asking either question writes the file.
func TestAMissingFileIsNeither(t *testing.T) {
	path := filepath.Join(t.TempDir(), "absent.dart")
	if IsStub(path) || IsImplemented(path) {
		t.Error("a file that is not there was reported as generated output")
	}
}

// TestPruningStillOwnsBothForms: the stub marker is a suffix of the same
// header line, so widening it must not have narrowed what pruning can clean
// up. A file pruning stops recognising is one nothing will ever delete.
func TestPruningStillOwnsBothForms(t *testing.T) {
	for _, header := range []string{StubHeader, ImplementedHeader} {
		got, err := isGenerated(writeMarked(t, header+"\nclass A {}\n"))
		if err != nil {
			t.Fatalf("isGenerated: %v", err)
		}
		if !got {
			t.Errorf("pruning no longer recognises %q", header)
		}
	}
}
