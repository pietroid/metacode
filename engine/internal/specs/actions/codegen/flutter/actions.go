// Package actionsflutter maps the action catalog onto Flutter: the call a
// wrapper makes, and the expectation a generated test verifies it with.
//
// Two mappings per verb, and both belong here. Everything else in the engine
// needs only the first, because a widget or a store is observed by reading
// what is on screen; an action leaves no state behind, so how it is checked is
// as much a property of the verb as how it is called.
package actionsflutter

import (
	"fmt"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/actions/catalog"
)

// SpyVariable is the recorder a generated test passes to the router and reads
// its expectations off.
const SpyVariable = "navigation"

// SpyClass is the observer class the test support file declares.
const SpyClass = "NavigationSpy"

// Call is the Dart a wrapper runs for one action binding.
//
// Both navigator verbs are go_router extensions on BuildContext, which is what
// makes a wrapper the only place they can live: a Cubit has no context, and a
// route is pushed against one. See AGENTS.md, "A wrapper composes the dumb
// widget".
func Call(b model.ActionBinding) (string, error) {
	if b.Subject != actioncatalog.SubjectNavigator {
		return "", fmt.Errorf("no Flutter mapping for action subject %q", b.Subject)
	}
	switch b.Verb {
	case actioncatalog.VerbPush:
		return fmt.Sprintf("context.pushNamed(%s)", dart.DartStringLiteral(b.Arg)), nil
	case actioncatalog.VerbPop:
		return "context.pop()", nil
	default:
		return "", fmt.Errorf("no Flutter mapping for %s.%s", b.Subject, b.Verb)
	}
}

// Imports is the package a wrapper needs to make the call.
func Imports() []string { return []string{"package:go_router/go_router.dart"} }

// Verify is the expectation a test makes about one action assertion.
//
// The count is one, always, and there is no way to write anything else yet. A
// verification that passes on a double push hides the most common navigation
// bug there is, and a `.count` that loosens it later is compatible with every
// spec written under this rule.
func Verify(a *model.Assertion) (string, error) {
	if a.Target != actioncatalog.SubjectNavigator {
		return "", fmt.Errorf("no Flutter verification for action subject %q", a.Target)
	}
	switch a.Verb {
	case actioncatalog.VerbPush:
		return fmt.Sprintf("expect(%s.pushed.where((route) => route == %s).length, 1);",
			SpyVariable, dart.DartStringLiteral(a.Value)), nil
	case actioncatalog.VerbPop:
		return fmt.Sprintf("expect(%s.popped.length, 1);", SpyVariable), nil
	default:
		return "", fmt.Errorf("no Flutter verification for %s.%s", a.Target, a.Verb)
	}
}
