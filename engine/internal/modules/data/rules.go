// Package data contains the interpretation and validation rules for the data spec.
package data

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
)

// Validate checks that every store has the minimum required fields.
func Validate(stores []ir.Store) []error {
	var errs []error
	for _, s := range stores {
		if s.ValueType == "" {
			errs = append(errs, fmt.Errorf("data.yaml > %s: missing value type", s.Name))
		}
	}
	return errs
}

// DartTypeFor maps a Metacode primitive type to its Dart equivalent.
func DartTypeFor(metaType string) string {
	switch strings.ToLower(metaType) {
	case "int", "integer":
		return "int"
	case "string":
		return "String"
	case "bool", "boolean":
		return "bool"
	case "num", "number", "double":
		return "num"
	default:
		return "dynamic"
	}
}

// DartLiteral returns a Dart literal for v according to dartType.
func DartLiteral(v any, dartType string) string {
	if v == nil {
		return "null"
	}
	switch val := v.(type) {
	case string:
		return shared.DartStringLiteral(val)
	case bool:
		return strconv.FormatBool(val)
	case int:
		return strconv.Itoa(val)
	case int64:
		return strconv.FormatInt(val, 10)
	case float64:
		return strconv.FormatFloat(val, 'f', -1, 64)
	default:
		s := fmt.Sprintf("%v", val)
		if _, err := strconv.ParseFloat(s, 64); err == nil {
			return s
		}
		return shared.DartStringLiteral(s)
	}
}

// IsNumericType reports whether metaType represents a numeric Dart type.
func IsNumericType(metaType string) bool {
	switch strings.ToLower(metaType) {
	case "int", "integer", "num", "number", "double":
		return true
	}
	return false
}

// SplitDot splits s at the first dot. If there is no dot, it returns s and "".
func SplitDot(s string) (string, string) {
	parts := strings.SplitN(s, ".", 2)
	if len(parts) != 2 {
		return s, ""
	}
	return parts[0], parts[1]
}
