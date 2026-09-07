// Package ui contains the interpretation and validation rules for the UI spec.
package ui

import (
	"fmt"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
)

// Validate checks every UI component against the UI catalog and reports
// problems such as unknown props. Custom widgets are not validated here.
func Validate(components []ir.UIComponent, c *catalog.Catalog) []error {
	var errs []error
	for _, comp := range components {
		errs = append(errs, validateComponent(comp, c)...)
	}
	return errs
}

func validateComponent(comp ir.UIComponent, c *catalog.Catalog) []error {
	var errs []error
	sym, ok := c.Find(comp.Kind)
	if !ok {
		// Custom widgets are validated by symbol resolution, not the catalog.
		return errs
	}

	allowed := make(map[string]bool, len(sym.AllowedProps)+1)
	allowed[sym.DefaultProp] = true
	for _, p := range sym.AllowedProps {
		allowed[p] = true
	}

	for prop := range comp.Props {
		if !allowed[prop] {
			errs = append(errs, fmt.Errorf("ui.yaml > %s: prop %q is not allowed for %s", comp.Name, prop, comp.Kind))
		}
	}

	for _, child := range comp.Children {
		errs = append(errs, validateComponent(child, c)...)
	}
	return errs
}
