package dart

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/pietroid/metacode/engine/internal/order"
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

// DartTypeFor maps a Metacode type to its Dart equivalent.
//
// A declared model name maps to its class, so `list(task)` is `List<Task>`.
func DartTypeFor(metaType string) string {
	if inner, ok := ListElementType(metaType); ok {
		return "List<" + DartTypeFor(inner) + ">"
	}
	switch strings.ToLower(metaType) {
	case "int", "integer":
		return "int"
	case "string":
		return "String"
	case "bool", "boolean":
		return "bool"
	case "num", "number", "double":
		return "num"
	case "datetime":
		return "DateTime"
	case "", "any", "dynamic":
		return "dynamic"
	default:
		// Anything else names a shape models.yaml declares. That the name is
		// declared is checked in the model rules, so a typo is an error there
		// rather than a class here that nothing wrote.
		return PascalCase(metaType)
	}
}

// RawLiteral renders a value whose type no spec declares: a field of a stored
// element, or a count. It reads what the value looks like, which is all there
// is to go on until models.yaml gives elements a shape.
func RawLiteral(raw string) string {
	switch strings.ToLower(raw) {
	case "true":
		return "true"
	case "false":
		return "false"
	}
	if _, err := strconv.ParseFloat(raw, 64); err == nil {
		return raw
	}
	return DartStringLiteral(raw)
}

// VariableType maps a Metacode UI variable type to its Dart declaration. The
// spec's words are on the left and Dart is on the right, so a target that is
// not Flutter answers this differently and nothing above it changes.
func VariableType(metaType string) string {
	switch metaType {
	case "text":
		return "String"
	case "boolean":
		return "bool"
	case "number":
		return "num"
	case "list":
		return "List<dynamic>"
	case "widget":
		return "Widget"
	case "callback":
		return "VoidCallback?"
	case "callback(text)":
		return "ValueChanged<String>?"
	case "callback(boolean)":
		return "ValueChanged<bool?>?"
	case "callback(number)":
		return "ValueChanged<double>?"
	case "callback(any)":
		return "ValueChanged<dynamic>?"
	default:
		return "dynamic"
	}
}

// VariablePlaceholder is a value of the given type that compiles, used where a
// generator has to pass something it was never told.
func VariablePlaceholder(metaType string) string {
	switch metaType {
	case "text":
		return "''"
	case "boolean":
		return "false"
	case "number":
		return "0"
	case "list":
		return "const []"
	case "widget":
		return "SizedBox()"
	default:
		return "null"
	}
}

// ListElementType reads the element type out of `list(task)`. It reports false
// for anything that is not a list.
func ListElementType(metaType string) (string, bool) {
	t := strings.TrimSpace(metaType)
	lower := strings.ToLower(t)
	if !strings.HasPrefix(lower, "list(") || !strings.HasSuffix(lower, ")") {
		return "", false
	}
	return strings.TrimSpace(t[len("list(") : len(t)-1]), true
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
	case []any:
		return dartListLiteral(val, dartType)
	case map[string]any:
		return dartMapLiteral(val, dartType)
	default:
		s := fmt.Sprintf("%v", val)
		if _, err := strconv.ParseFloat(s, 64); err == nil {
			return s
		}
		return DartStringLiteral(s)
	}
}

// dartListLiteral renders a seeded list. The element type comes from the store's
// own Dart type, so a List<String> seeds strings and a List<dynamic> seeds maps.
func dartListLiteral(items []any, dartType string) string {
	element := "dynamic"
	if inner, ok := strings.CutPrefix(dartType, "List<"); ok {
		element = strings.TrimSuffix(inner, ">")
	}
	parts := make([]string, 0, len(items))
	for _, item := range items {
		parts = append(parts, DartLiteral(item, element))
	}
	return "[" + strings.Join(parts, ", ") + "]"
}

// dartMapLiteral renders a mapping. When the type it fills is a declared class
// the mapping is that class being built, so the keys are named arguments rather
// than string keys. Keys are walked in order so identical specs produce
// identical bytes.
func dartMapLiteral(m map[string]any, dartType string) string {
	named := IsClassName(dartType)
	parts := make([]string, 0, len(m))
	for _, key := range order.Keys(m) {
		name := DartStringLiteral(key)
		if named {
			name = key
		}
		parts = append(parts, name+": "+DartLiteral(m[key], "dynamic"))
	}
	if named {
		return dartType + "(" + strings.Join(parts, ", ") + ")"
	}
	return "{" + strings.Join(parts, ", ") + "}"
}

// IsClassName reports whether a Dart type is a class this project declared,
// rather than a builtin or a container.
func IsClassName(dartType string) bool {
	switch dartType {
	case "", "dynamic", "String", "int", "num", "double", "bool", "Object", "DateTime", "Widget":
		return false
	}
	if strings.ContainsAny(dartType, "<>?") {
		return false
	}
	r := rune(dartType[0])
	return r >= 'A' && r <= 'Z'
}
