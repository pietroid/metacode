package spec

import (
	"os"
	"path/filepath"
	"testing"
)

func writeEnv(t *testing.T, dir, contents string) string {
	t.Helper()
	path := filepath.Join(dir, FileName)
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatalf("write .env: %s", err)
	}
	return path
}

func TestLoadSetsVariables(t *testing.T) {
	dir := t.TempDir()
	writeEnv(t, dir, "ANTHROPIC_API_KEY=sk-ant-test\n")
	t.Setenv("ANTHROPIC_API_KEY", "")
	os.Unsetenv("ANTHROPIC_API_KEY")

	if _, err := Load(dir); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if got := os.Getenv("ANTHROPIC_API_KEY"); got != "sk-ant-test" {
		t.Fatalf("ANTHROPIC_API_KEY = %q, want sk-ant-test", got)
	}
}

func TestLoadDoesNotOverrideExistingVariables(t *testing.T) {
	dir := t.TempDir()
	writeEnv(t, dir, "METACODE_LLM_MODEL=from-file\n")
	t.Setenv("METACODE_LLM_MODEL", "from-shell")

	if _, err := Load(dir); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if got := os.Getenv("METACODE_LLM_MODEL"); got != "from-shell" {
		t.Fatalf("METACODE_LLM_MODEL = %q, want from-shell", got)
	}
}

func TestLoadSearchesParentDirectories(t *testing.T) {
	root := t.TempDir()
	writeEnv(t, root, "METACODE_LLM_BASE_URL=https://example.test\n")
	nested := filepath.Join(root, "a", "b")
	if err := os.MkdirAll(nested, 0o755); err != nil {
		t.Fatalf("mkdir: %s", err)
	}
	t.Setenv("METACODE_LLM_BASE_URL", "")
	os.Unsetenv("METACODE_LLM_BASE_URL")

	path, err := Load(nested)
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if path == "" {
		t.Fatal("expected .env to be found in a parent directory")
	}
	if got := os.Getenv("METACODE_LLM_BASE_URL"); got != "https://example.test" {
		t.Fatalf("METACODE_LLM_BASE_URL = %q", got)
	}
}

func TestLoadMissingFileIsNotAnError(t *testing.T) {
	// A temp dir has no .env, but its parents might, so point at the root.
	path, err := Load(string(filepath.Separator))
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	_ = path
}

func TestParseLine(t *testing.T) {
	cases := []struct {
		line      string
		key       string
		value     string
		supported bool
	}{
		{line: "KEY=value", key: "KEY", value: "value", supported: true},
		{line: "  KEY = value  ", key: "KEY", value: "value", supported: true},
		{line: `KEY="quoted value"`, key: "KEY", value: "quoted value", supported: true},
		{line: "KEY='quoted'", key: "KEY", value: "quoted", supported: true},
		{line: "export KEY=value", key: "KEY", value: "value", supported: true},
		{line: "KEY=", key: "KEY", value: "", supported: true},
		{line: "# comment", supported: false},
		{line: "", supported: false},
		{line: "NOT_AN_ASSIGNMENT", supported: false},
		{line: "=orphan", supported: false},
	}

	for _, tc := range cases {
		key, value, ok := parseLine(tc.line)
		if ok != tc.supported {
			t.Fatalf("parseLine(%q) ok = %v, want %v", tc.line, ok, tc.supported)
		}
		if !ok {
			continue
		}
		if key != tc.key || value != tc.value {
			t.Fatalf("parseLine(%q) = (%q, %q), want (%q, %q)", tc.line, key, value, tc.key, tc.value)
		}
	}
}
