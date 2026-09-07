package spec

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

// DataField describes a single field inside a data store.
type DataField struct {
	Name         string
	Type         string
	InitialValue string
}

// DataSpec describes a persistent/ephemeral data store.
type DataSpec struct {
	Name        string
	StorageType string
	Fields      []DataField
}

// WidgetNode is a node in the UI widget tree.
type WidgetNode struct {
	Kind     string
	Props    map[string]interface{}
	Children []WidgetNode
	Content  string
}

// UISpec describes a reusable widget or page.
type UISpec struct {
	Name string
	Root WidgetNode
}

// Assignment is a target=value pair used in givens/thens.
type Assignment struct {
	Target string
	Value  string
}

// Action describes a when/then clause.
type Action struct {
	Raw          string
	Target       string
	Path         []string
	IsAssignment bool
	Value        string
}

// TestSpec describes a single scenario.
type TestSpec struct {
	Name  string
	Given []Assignment
	When  *Action
	Then  []Action
}

// SpecSet holds all parsed specs.
type SpecSet struct {
	DataStores map[string]*DataSpec
	UIWidgets  map[string]*UISpec
	Tests      []*TestSpec
}

// LoadSpecs reads every .yaml/.yml file in dir and parses it.
func LoadSpecs(dir string) (*SpecSet, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, fmt.Errorf("reading spec dir %s: %w", dir, err)
	}

	set := &SpecSet{
		DataStores: map[string]*DataSpec{},
		UIWidgets:  map[string]*UISpec{},
	}

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if !strings.HasSuffix(name, ".yaml") && !strings.HasSuffix(name, ".yml") {
			continue
		}
		path := filepath.Join(dir, name)
		data, err := os.ReadFile(path)
		if err != nil {
			return nil, fmt.Errorf("reading %s: %w", path, err)
		}

		var raw map[string]interface{}
		if err := yaml.Unmarshal(data, &raw); err != nil {
			return nil, fmt.Errorf("parsing %s: %w", path, err)
		}

		for k, v := range raw {
			if err := ingestTopLevel(set, k, v); err != nil {
				return nil, fmt.Errorf("%s in %s: %w", k, path, err)
			}
		}
	}

	return set, nil
}

func ingestTopLevel(set *SpecSet, name string, v interface{}) error {
	m, ok := v.(map[string]interface{})
	if !ok {
		return fmt.Errorf("expected map, got %T", v)
	}

	if isTest(m) {
		t, err := parseTest(name, m)
		if err != nil {
			return err
		}
		set.Tests = append(set.Tests, t)
		return nil
	}

	if isData(m) {
		d, err := parseData(name, m)
		if err != nil {
			return err
		}
		set.DataStores[name] = d
		return nil
	}

	root, err := parseWidgetNode(m)
	if err != nil {
		return err
	}
	set.UIWidgets[name] = &UISpec{Name: name, Root: root}
	return nil
}

func isTest(m map[string]interface{}) bool {
	for _, key := range []string{"given", "when", "then"} {
		if _, ok := m[key]; ok {
			return true
		}
	}
	return false
}

func isData(m map[string]interface{}) bool {
	_, ok := m["type"]
	return ok
}

func parseData(name string, m map[string]interface{}) (*DataSpec, error) {
	ds := &DataSpec{Name: name}
	if t, ok := m["type"].(string); ok {
		ds.StorageType = t
	}

	var initial string
	switch iv := m["initialValue"].(type) {
	case string:
		initial = iv
	case int:
		initial = fmt.Sprintf("%d", iv)
	case float64:
		initial = fmt.Sprintf("%v", iv)
	case bool:
		initial = fmt.Sprintf("%t", iv)
	}

	for k, v := range m {
		if k == "type" || k == "initialValue" {
			continue
		}
		typ, ok := v.(string)
		if !ok {
			return nil, fmt.Errorf("field %s must have a string type, got %T", k, v)
		}
		field := DataField{Name: k, Type: typ}
		ds.Fields = append(ds.Fields, field)
	}

	if initial != "" {
		assigned := false
		for i := range ds.Fields {
			if ds.Fields[i].Name == "value" {
				ds.Fields[i].InitialValue = initial
				assigned = true
				break
			}
		}
		if !assigned && len(ds.Fields) > 0 {
			ds.Fields[0].InitialValue = initial
		}
	}

	return ds, nil
}

func parseTest(name string, m map[string]interface{}) (*TestSpec, error) {
	t := &TestSpec{Name: name}
	var err error

	t.Given, err = parseAssignments(m["given"])
	if err != nil {
		return nil, fmt.Errorf("given: %w", err)
	}

	t.When, err = parseAction(m["when"])
	if err != nil {
		return nil, fmt.Errorf("when: %w", err)
	}

	t.Then, err = parseActions(m["then"])
	if err != nil {
		return nil, fmt.Errorf("then: %w", err)
	}

	return t, nil
}

func parseAssignments(v interface{}) ([]Assignment, error) {
	if v == nil {
		return nil, nil
	}
	switch x := v.(type) {
	case string:
		if strings.TrimSpace(x) == "" {
			return nil, nil
		}
		a, err := parseAssignment(x)
		if err != nil {
			return nil, err
		}
		return []Assignment{a}, nil
	case []interface{}:
		var res []Assignment
		for _, item := range x {
			s, ok := item.(string)
			if !ok {
				return nil, fmt.Errorf("expected string in list, got %T", item)
			}
			a, err := parseAssignment(s)
			if err != nil {
				return nil, err
			}
			res = append(res, a)
		}
		return res, nil
	default:
		return nil, fmt.Errorf("expected string or list, got %T", v)
	}
}

func parseAssignment(s string) (Assignment, error) {
	if !strings.Contains(s, "=") {
		return Assignment{}, fmt.Errorf("assignment must contain '=': %q", s)
	}
	parts := strings.SplitN(s, "=", 2)
	return Assignment{
		Target: strings.TrimSpace(parts[0]),
		Value:  strings.TrimSpace(parts[1]),
	}, nil
}

func parseAction(v interface{}) (*Action, error) {
	if v == nil {
		return nil, nil
	}
	s, ok := v.(string)
	if !ok {
		return nil, fmt.Errorf("expected string, got %T", v)
	}
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, nil
	}

	a := &Action{Raw: s}
	if strings.Contains(s, "=") {
		parts := strings.SplitN(s, "=", 2)
		a.IsAssignment = true
		a.Target = strings.TrimSpace(parts[0])
		a.Value = strings.TrimSpace(parts[1])
	} else {
		a.Target = s
	}
	a.Path = strings.Split(a.Target, ".")
	return a, nil
}

func parseActions(v interface{}) ([]Action, error) {
	if v == nil {
		return nil, nil
	}
	switch x := v.(type) {
	case string:
		if strings.TrimSpace(x) == "" {
			return nil, nil
		}
		a, err := parseAction(x)
		if err != nil {
			return nil, err
		}
		return []Action{*a}, nil
	case []interface{}:
		var res []Action
		for _, item := range x {
			s, ok := item.(string)
			if !ok {
				return nil, fmt.Errorf("expected string in list, got %T", item)
			}
			a, err := parseAction(s)
			if err != nil {
				return nil, err
			}
			res = append(res, *a)
		}
		return res, nil
	default:
		return nil, fmt.Errorf("expected string or list, got %T", v)
	}
}

// Known widget keys. Order matters because a node should contain exactly one
// of them; we check in this order.
var widgetKinds = []string{"stack", "center", "text", "button"}

func parseWidgetNode(m map[string]interface{}) (WidgetNode, error) {
	for _, kind := range widgetKinds {
		if v, ok := m[kind]; ok {
			return buildWidgetNode(kind, v)
		}
	}
	for k := range m {
		if strings.HasPrefix(k, "aligned.") {
			return buildWidgetNode(k, m[k])
		}
	}
	return WidgetNode{}, fmt.Errorf("unknown widget node keys: %v", keys(m))
}

func buildWidgetNode(kind string, v interface{}) (WidgetNode, error) {
	node := WidgetNode{Kind: kind, Props: map[string]interface{}{}}

	switch kind {
	case "stack":
		list, ok := v.([]interface{})
		if !ok {
			return WidgetNode{}, fmt.Errorf("stack expects a list, got %T", v)
		}
		for _, item := range list {
			childMap, ok := item.(map[string]interface{})
			if !ok {
				return WidgetNode{}, fmt.Errorf("stack child must be a widget map, got %T", item)
			}
			child, err := parseWidgetNode(childMap)
			if err != nil {
				return WidgetNode{}, err
			}
			node.Children = append(node.Children, child)
		}

	case "center":
		child, err := childFromValue(v)
		if err != nil {
			return WidgetNode{}, fmt.Errorf("center: %w", err)
		}
		node.Children = append(node.Children, child)

	case "text":
		s, ok := v.(string)
		if !ok {
			return WidgetNode{}, fmt.Errorf("text expects a string content, got %T", v)
		}
		node.Content = s

	case "button":
		props, ok := v.(map[string]interface{})
		if !ok {
			return WidgetNode{}, fmt.Errorf("button expects a property map, got %T", v)
		}
		node.Props = props

	default:
		if strings.HasPrefix(kind, "aligned.") {
			node.Kind = "align"
			node.Props["alignment"] = strings.TrimPrefix(kind, "aligned.")
			child, err := childFromValue(v)
			if err != nil {
				return WidgetNode{}, fmt.Errorf("aligned: %w", err)
			}
			node.Children = append(node.Children, child)
		} else {
			return WidgetNode{}, fmt.Errorf("unknown widget kind %q", kind)
		}
	}

	return node, nil
}

func childFromValue(v interface{}) (WidgetNode, error) {
	switch x := v.(type) {
	case map[string]interface{}:
		return parseWidgetNode(x)
	case string:
		return WidgetNode{Kind: "reference", Content: x}, nil
	default:
		return WidgetNode{}, fmt.Errorf("expected widget map or reference string, got %T", v)
	}
}

func keys(m map[string]interface{}) []string {
	var out []string
	for k := range m {
		out = append(out, k)
	}
	return out
}
