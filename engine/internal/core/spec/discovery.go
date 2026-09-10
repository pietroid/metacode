// Package spec implements spec discovery and raw YAML parsing for the engine core.
package spec

import (
	"fmt"
	"os"
	"path/filepath"
)

// Paths holds absolute file system locations for the discovered specs.
type Paths struct {
	Root       string // absolute path to project root
	Metacode   string // absolute path to metacode folder
	Project    string
	Data       string
	UI         string
	Behaviors  string
	Models     string // optional: "" when the project declares no models
	Navigation string // optional: "" when the project declares no routes
}

// requiredFiles is every spec a project must have: the canonical file name,
// and the field of Paths that carries it. The accessor is a function rather
// than a name so one table both fills the field and reads it back; two tables
// drifted the first time a spec kind was added to only one of them.
var requiredFiles = []struct {
	name  string
	field func(*Paths) *string
}{
	{"project.yaml", func(p *Paths) *string { return &p.Project }},
	{"data.yaml", func(p *Paths) *string { return &p.Data }},
	{"ui.yaml", func(p *Paths) *string { return &p.UI }},
	{"behaviors.yaml", func(p *Paths) *string { return &p.Behaviors }},
}

// optionalFiles are the specs a project may leave out. models.yaml is absent
// when every store holds a primitive; navigation.yaml is absent when the app
// is one page, and the UI spec already names it.
var optionalFiles = []struct {
	name  string
	field func(*Paths) *string
}{
	{"models.yaml", func(p *Paths) *string { return &p.Models }},
	{"navigation.yaml", func(p *Paths) *string { return &p.Navigation }},
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
		Root:      root,
		Metacode:  metacodeDir,
		Project:   filepath.Join(metacodeDir, "project.yaml"),
		Data:      filepath.Join(metacodeDir, "data.yaml"),
		UI:        filepath.Join(metacodeDir, "ui.yaml"),
		Behaviors: filepath.Join(metacodeDir, "behaviors.yaml"),
	}

	for _, f := range optionalFiles {
		if path := filepath.Join(metacodeDir, f.name); fileExists(path) {
			*f.field(&paths) = path
		}
	}

	for _, req := range requiredFiles {
		if err := requireFile(*req.field(&paths), metacodeDir, req.name); err != nil {
			return Paths{}, err
		}
	}

	return paths, nil
}

// requireFile reports a spec the project has to have and does not.
func requireFile(path, metacodeDir, name string) error {
	_, err := os.Stat(path)
	switch {
	case err == nil:
		return nil
	case os.IsNotExist(err):
		return fmt.Errorf("required spec file missing: %s/%s", metacodeDir, name)
	default:
		return fmt.Errorf("stat %s: %w", path, err)
	}
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

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}
