package graph

import (
	"fmt"
	"strings"

	"metacode/internal/spec"
	"metacode/internal/utils"
)

// Store wraps a parsed data spec.
type Store struct {
	spec.DataSpec
}

// Widget wraps a parsed UI spec.
type Widget struct {
	spec.UISpec
}

// Test wraps a parsed test spec.
type Test struct {
	spec.TestSpec
}

// TextBinding maps a UI display key to a store field.
type TextBinding struct {
	StoreName  string
	FieldName  string
	DisplayKey string
}

// Project is the resolved symbol graph used by generators.
type Project struct {
	SpecDir       string
	OutputDir     string
	Stores        map[string]*Store
	Widgets       map[string]*Widget
	Tests         []*Test
	TextBindings  map[string]TextBinding
	ButtonActions map[string]string
}

// Build resolves the parsed specs into a project graph.
func Build(set *spec.SpecSet) (*Project, error) {
	p := &Project{
		Stores:        map[string]*Store{},
		Widgets:       map[string]*Widget{},
		TextBindings:  map[string]TextBinding{},
		ButtonActions: map[string]string{},
	}

	for name, ds := range set.DataStores {
		p.Stores[name] = &Store{*ds}
	}
	for name, us := range set.UIWidgets {
		p.Widgets[name] = &Widget{*us}
	}
	for _, t := range set.Tests {
		p.Tests = append(p.Tests, &Test{*t})
	}

	if err := p.resolveBindings(); err != nil {
		return nil, err
	}
	return p, nil
}

func (p *Project) resolveBindings() error {
	for name, store := range p.Stores {
		prefix := storePrefix(name)
		for _, field := range store.Fields {
			displayKey := prefix + utils.TitleCase(field.Name)
			p.TextBindings[displayKey] = TextBinding{
				StoreName:  name,
				FieldName:  field.Name,
				DisplayKey: displayKey,
			}
		}
	}

	for _, test := range p.Tests {
		if test.When == nil || len(test.When.Path) == 0 {
			continue
		}
		path := test.When.Path
		last := path[len(path)-1]
		if last != "onPressed" {
			continue
		}
		widgetName := path[len(path)-2]
		if _, ok := p.Widgets[widgetName]; !ok {
			continue
		}
		if len(test.Then) != 1 {
			continue
		}
		then := test.Then[0]
		if then.IsAssignment || len(then.Path) < 2 {
			continue
		}
		storeName := then.Path[0]
		if _, ok := p.Stores[storeName]; !ok {
			return fmt.Errorf("test %q references unknown store %q in then", test.Name, storeName)
		}
		method := then.Path[len(then.Path)-1]
		p.ButtonActions[widgetName] = fmt.Sprintf("%s.%s", utils.ToLowerCamel(storeName), method)
	}

	return nil
}

func storePrefix(name string) string {
	// Drop a trailing "Store" suffix to form a natural display prefix.
	base := name
	if strings.HasSuffix(name, "Store") {
		base = strings.TrimSuffix(name, "Store")
	}
	return utils.LowerFirst(base)
}

// StoreMethods returns all method names invoked on a given store across tests.
func (p *Project) StoreMethods(storeName string) map[string]bool {
	methods := map[string]bool{}
	for _, test := range p.Tests {
		collectMethods(test.When, storeName, methods)
		for _, then := range test.Then {
			if !then.IsAssignment {
				collectMethods(&then, storeName, methods)
			}
		}
	}
	return methods
}

func collectMethods(a *spec.Action, storeName string, out map[string]bool) {
	if a == nil || len(a.Path) < 2 {
		return
	}
	if a.Path[0] != storeName {
		return
	}
	out[a.Path[len(a.Path)-1]] = true
}

// IsUIPath returns true if the first segment of path refers to a UI widget.
func (p *Project) IsUIPath(path []string) bool {
	if len(path) == 0 {
		return false
	}
	_, ok := p.Widgets[path[0]]
	return ok
}

// IsStorePath returns true if the first segment of path refers to a data store.
func (p *Project) IsStorePath(path []string) bool {
	if len(path) == 0 {
		return false
	}
	_, ok := p.Stores[path[0]]
	return ok
}

// DisplayKeyForStoreField returns the auto-generated display key for a store field.
func (p *Project) DisplayKeyForStoreField(storeName, fieldName string) string {
	prefix := storePrefix(storeName)
	return prefix + utils.TitleCase(fieldName)
}
