// Package env loads key/value pairs from a .env file into the process
// environment.
//
// Metacode needs an Anthropic API key, but exporting ANTHROPIC_API_KEY in the
// shell leaks it into every other tool started from that shell. Keeping the key
// in a gitignored .env next to the project scopes it to Metacode alone.
package spec

import (
	"bufio"
	"os"
	"path/filepath"
	"strings"
)

// FileName is the file Load looks for.
const FileName = ".env"

// Load reads the nearest .env file, searching dir and then each parent
// directory, and sets every variable it defines that is not already present in
// the environment. Variables already set win, so an explicit export or a CI
// secret always overrides the file.
//
// A missing .env is not an error: the file is optional and the environment
// alone is a valid configuration. Load returns the path it loaded, or "" when
// no file was found.
func Load(dir string) (string, error) {
	path, ok := find(dir)
	if !ok {
		return "", nil
	}
	if err := LoadFile(path); err != nil {
		return "", err
	}
	return path, nil
}

// LoadFile applies a specific .env file, again without overriding variables
// that are already set.
func LoadFile(path string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		key, value, ok := parseLine(scanner.Text())
		if !ok {
			continue
		}
		if _, present := os.LookupEnv(key); present {
			continue
		}
		if err := os.Setenv(key, value); err != nil {
			return err
		}
	}
	return scanner.Err()
}

// find walks up from dir looking for a .env file.
func find(dir string) (string, bool) {
	abs, err := filepath.Abs(dir)
	if err != nil {
		return "", false
	}
	for {
		candidate := filepath.Join(abs, FileName)
		if info, err := os.Stat(candidate); err == nil && !info.IsDir() {
			return candidate, true
		}
		parent := filepath.Dir(abs)
		if parent == abs {
			return "", false
		}
		abs = parent
	}
}

// parseLine reads one KEY=VALUE line. Blank lines, comments and lines without
// a key are skipped. A leading "export " is tolerated so the same file can be
// sourced by a shell, and a fully quoted value has its quotes stripped.
func parseLine(line string) (key, value string, ok bool) {
	trimmed := strings.TrimSpace(line)
	if trimmed == "" || strings.HasPrefix(trimmed, "#") {
		return "", "", false
	}
	trimmed = strings.TrimPrefix(trimmed, "export ")

	key, value, found := strings.Cut(trimmed, "=")
	if !found {
		return "", "", false
	}
	key = strings.TrimSpace(key)
	if key == "" {
		return "", "", false
	}
	return key, unquote(strings.TrimSpace(value)), true
}

// unquote strips a matching pair of surrounding quotes. An unquoted value keeps
// any trailing inline comment, because a bare # is legal inside a key.
func unquote(value string) string {
	if len(value) < 2 {
		return value
	}
	first, last := value[0], value[len(value)-1]
	if first == last && (first == '"' || first == '\'') {
		return value[1 : len(value)-1]
	}
	return value
}
