// Package dart holds the checks applied to Dart source that came back from a
// model, before it is written to disk.
//
// Both places that ask a model for Dart need these: the wrapper generator and
// the fix loop. The fix loop used to skip them, and wrote whatever it was
// handed. A fix for a wrapper once came back as two bare Cubit methods, with no
// class at all, and was written to the wrapper file unchallenged.
package dart

import (
	"fmt"
	"regexp"
	"strings"
)

var codeFence = regexp.MustCompile("```(?:dart)?\\s*\\n(?s)(.*?)\\n```")
var classDecl = regexp.MustCompile(`class\s+(\w+)\s+extends\s+StatelessWidget`)

// ExtractCode returns the contents of the last Dart code fence in raw.
func ExtractCode(raw string) (string, error) {
	matches := codeFence.FindAllStringSubmatch(raw, -1)
	if len(matches) == 0 {
		return "", fmt.Errorf("no dart code fence found")
	}
	return strings.TrimSpace(matches[len(matches)-1][1]), nil
}

// Validate rejects source that is obviously not a Dart file. It is a shape
// check, not a compiler: the tests are the real verdict.
func Validate(code string) error {
	if strings.TrimSpace(code) == "" {
		return fmt.Errorf("generated code is empty")
	}
	if !strings.Contains(code, "class ") {
		return fmt.Errorf("generated code missing class declaration")
	}
	if !Balanced(code) {
		return fmt.Errorf("generated code has unbalanced brackets")
	}
	return nil
}

// ClassName returns the name of the StatelessWidget the code declares, if any.
func ClassName(code string) string {
	m := classDecl.FindStringSubmatch(code)
	if len(m) < 2 {
		return ""
	}
	return m[1]
}

// RenameClass rewrites the declared widget class, and every reference to it,
// to want. A model is asked for a particular class name and is free to ignore
// the request; the rest of the generated app is not.
func RenameClass(code, want string) string {
	got := ClassName(code)
	if got == "" || got == want {
		return code
	}
	return regexp.MustCompile(`\b`+regexp.QuoteMeta(got)+`\b`).ReplaceAllString(code, want)
}

// Balanced reports whether brackets are balanced, ignoring anything inside a
// string literal or a comment.
//
// Comments have to be skipped, not just strings. A doc comment reading
// "seed a scenario's Given state" opens a string that never closes, and every
// bracket after it stops counting: a correct file came back from the model,
// failed this check, and was silently discarded, three times in a row, while
// the run reported the scaffolded placeholder as the model's work.
func Balanced(code string) bool {
	depth := 0
	runes := []rune(code)

	for i := 0; i < len(runes); i++ {
		r := runes[i]

		switch {
		case r == '/' && i+1 < len(runes) && runes[i+1] == '/':
			i = skipLineComment(runes, i)
		case r == '/' && i+1 < len(runes) && runes[i+1] == '*':
			end := skipBlockComment(runes, i)
			if end < 0 {
				return false // unterminated comment
			}
			i = end
		case r == '"' || r == '\'':
			end := skipString(runes, i)
			if end < 0 {
				return false // unterminated string
			}
			i = end
		case r == '{' || r == '(' || r == '[':
			depth++
		case r == '}' || r == ')' || r == ']':
			depth--
			if depth < 0 {
				return false
			}
		}
	}

	return depth == 0
}

// skipLineComment returns the index of the last rune of the comment.
func skipLineComment(runes []rune, start int) int {
	for i := start; i < len(runes); i++ {
		if runes[i] == '\n' {
			return i
		}
	}
	return len(runes) - 1
}

// skipBlockComment returns the index of the closing slash, or -1 if the comment
// is unterminated. Dart block comments nest.
func skipBlockComment(runes []rune, start int) int {
	depth := 0
	for i := start; i < len(runes)-1; i++ {
		switch {
		case runes[i] == '/' && runes[i+1] == '*':
			depth++
			i++
		case runes[i] == '*' && runes[i+1] == '/':
			depth--
			i++
			if depth == 0 {
				return i
			}
		}
	}
	return -1
}

// skipString returns the index of the closing quote, or -1 if the literal is
// unterminated. It handles escapes and the triple-quoted form.
func skipString(runes []rune, start int) int {
	quote := runes[start]

	triple := start+2 < len(runes) && runes[start+1] == quote && runes[start+2] == quote
	if triple {
		for i := start + 3; i < len(runes)-2; i++ {
			if runes[i] == '\\' {
				i++
				continue
			}
			if runes[i] == quote && runes[i+1] == quote && runes[i+2] == quote {
				return i + 2
			}
		}
		return -1
	}

	for i := start + 1; i < len(runes); i++ {
		switch runes[i] {
		case '\\':
			i++
		case quote:
			return i
		case '\n':
			// A single-quoted Dart string cannot span lines. Treating it as
			// unterminated here would reject a whole file over one stray
			// apostrophe; stopping at the newline keeps the check to what it
			// is for, which is brackets.
			return i
		}
	}
	return -1
}
