package dart

import (
	"fmt"
	"strconv"
	"strings"
)

// This file is the single answer to "where does generated code go, and what is
// it called". Nothing else in the tree restates it: see docs/decisions.md,
// "Where a generated file goes is decided once".
//
// The rules belong to the target language, not to the specs. A scenario is
// "increments from 0" whatever it compiles to, which is what lets a second
// language answer these questions differently.

// WrapperFile is the file a widget's wrapper is written to, relative to the
// project root.
func WrapperFile(widget string) string {
	return fmt.Sprintf("lib/wrappers/%s_wrapper.dart", SnakeCase(widget))
}

// WrapperClass is the class a widget's wrapper declares.
func WrapperClass(widget string) string {
	return PascalCase(widget) + "Wrapper"
}

// WidgetFile is the file a declared widget is written to. Pages and plain
// widgets live in different directories.
func WidgetFile(widget string) string {
	dir := "lib/widgets"
	if IsPageName(widget) {
		dir = "lib/pages"
	}
	return fmt.Sprintf("%s/%s.dart", dir, SnakeCase(widget))
}

// WidgetClass is the class a declared widget declares.
func WidgetClass(widget string) string {
	return PascalCase(widget)
}

// CubitFile is the file a store's Cubit is written to.
func CubitFile(store string) string {
	return fmt.Sprintf("lib/stores/%s_cubit.dart", SnakeCase(StoreBaseName(store)))
}

// StateFile is the file a store's state class is written to.
func StateFile(store string) string {
	return fmt.Sprintf("lib/stores/%s_state.dart", SnakeCase(StoreBaseName(store)))
}

// CubitClass is the Cubit class generated for a store.
func CubitClass(store string) string {
	return PascalCase(StoreBaseName(store)) + "Cubit"
}

// StateClass is the state class generated for a store.
func StateClass(store string) string {
	return PascalCase(StoreBaseName(store)) + "State"
}

// TestFile is the file that verifies one scenario.
func TestFile(scenarioID string) string {
	return fmt.Sprintf("test/%s_test.dart", ScenarioSlug(scenarioID))
}

// ScenarioSlug turns a scenario path into a token usable in a file name.
// Scenario names are prose: see docs/decisions.md, "Scenario names are prose,
// so file names are slugs".
func ScenarioSlug(scenarioID string) string {
	var b strings.Builder
	lastUnderscore := true // never start with a separator
	for _, r := range scenarioID {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9':
			b.WriteRune(r)
			lastUnderscore = false
		default:
			if !lastUnderscore {
				b.WriteByte('_')
				lastUnderscore = true
			}
		}
	}
	return strings.TrimSuffix(b.String(), "_")
}

// ForwardedCallbackParam is the constructor parameter a widget exposes for one
// of its children's events: incrementButton.onPressed becomes
// incrementButtonOnPressed.
//
// Two generators have to agree on this name — the widget declares the
// parameter, the wrapper passes it — so neither one owns the rule.
func ForwardedCallbackParam(widget, event string) string {
	return widget + PascalCase(event)
}

// LibImport turns a path under lib/ into the form a Dart file inside lib/
// imports it by: "lib/stores/counter_cubit.dart" becomes
// "stores/counter_cubit.dart".
func LibImport(libPath string) string {
	return strings.TrimPrefix(libPath, "lib/")
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
		return DartStringLiteral(val)
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
		return DartStringLiteral(s)
	}
}
