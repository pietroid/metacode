// Package spec implements spec discovery and raw YAML parsing for the engine core.
package spec

import (
	"fmt"
	"os"
	"path/filepath"
)

// Paths holds absolute file system locations for the discovered specs.
type Paths struct {
	Root      string // absolute path to project root
	Metacode  string // absolute path to metacode folder
	Project   string
	Data      string
	UI        string
	Behaviors string
}

// requiredFiles maps the canonical spec filename to its Paths field.
var requiredFiles = []struct {
	name  string
	field string
}{
	{"project.yaml", "Project"},
	{"data.yaml", "Data"},
	{"ui.yaml", "UI"},
	{"behaviors.yaml", "Behaviors"},
}

// Discover walks upward from startDir looking for a metacode/ folder and
// validates that all required spec files are present.
func Discover(startDir string) (Paths, error) {
	if startDir == "" {
		startDir = "."
	}
	absStart, err := filepath.Abs(startDir)
	if err != nil {
		return Paths{}, fmt.Errorf("resolve start directory: %w", err)
	}

	root, found := findMetacodeRoot(absStart)
	if !found {
		return Paths{}, fmt.Errorf("no metacode/ folder found starting from %s", absStart)
	}

	metacodeDir := filepath.Join(root, "metacode")
	paths := Paths{
		Root:     root,
		Metacode: metacodeDir,
		Project:  filepath.Join(metacodeDir, "project.yaml"),
		Data:     filepath.Join(metacodeDir, "data.yaml"),
		UI:       filepath.Join(metacodeDir, "ui.yaml"),
		Behaviors: filepath.Join(metacodeDir, "behaviors.yaml"),
	}

	for _, req := range requiredFiles {
		var path string
		switch req.field {
		case "Project":
			path = paths.Project
		case "Data":
			path = paths.Data
		case "UI":
			path = paths.UI
		case "Behaviors":
			path = paths.Behaviors
		}
		if _, err := os.Stat(path); err != nil {
			if os.IsNotExist(err) {
				return Paths{}, fmt.Errorf("required spec file missing: %s/%s", metacodeDir, req.name)
			}
			return Paths{}, fmt.Errorf("stat %s: %w", path, err)
		}
	}

	return paths, nil
}

// findMetacodeRoot walks upward from dir until it finds a directory that
// contains a metacode/ subdirectory.
func findMetacodeRoot(dir string) (string, bool) {
	for {
		candidate := filepath.Join(dir, "metacode")
		info, err := os.Stat(candidate)
		if err == nil && info.IsDir() {
			return dir, true
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	return "", false
}
