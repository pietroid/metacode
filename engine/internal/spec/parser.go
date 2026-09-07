package spec

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// RawSpecs holds the generic YAML structures for the four spec files.
type RawSpecs struct {
	Project   map[string]any
	Data      map[string]any
	UI        map[string]any
	Behaviors map[string]any
}

// Parse reads the YAML files described by paths and returns generic structures.
func Parse(paths Paths) (RawSpecs, error) {
	project, err := parseMapFile(paths.Project)
	if err != nil {
		return RawSpecs{}, fmt.Errorf("parse project.yaml: %w", err)
	}
	data, err := parseMapFile(paths.Data)
	if err != nil {
		return RawSpecs{}, fmt.Errorf("parse data.yaml: %w", err)
	}
	ui, err := parseMapFile(paths.UI)
	if err != nil {
		return RawSpecs{}, fmt.Errorf("parse ui.yaml: %w", err)
	}
	behaviors, err := parseMapFile(paths.Behaviors)
	if err != nil {
		return RawSpecs{}, fmt.Errorf("parse behaviors.yaml: %w", err)
	}

	return RawSpecs{
		Project:   project,
		Data:      data,
		UI:        ui,
		Behaviors: behaviors,
	}, nil
}

func parseMapFile(path string) (map[string]any, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}

	var raw map[string]any
	if err := yaml.Unmarshal(data, &raw); err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	if raw == nil {
		raw = map[string]any{}
	}
	return raw, nil
}
