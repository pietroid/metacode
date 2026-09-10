package dart

import (
	"fmt"
	"regexp"
	"strings"
)

var classDecl = regexp.MustCompile(`class\s+(\w+)\s+extends\s+StatelessWidget`)

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
// Comments have to be skipped, not just strings. A check that could not read
// comments once discarded three good replies in a row over a bracket inside a
// doc comment, and reported the untouched scaffolding as the result.
func Balanced(code string) bool {
	depth := 0
	runes := []rune(code)

	for i := 0; i < len(runes); i++ {
		skipped, ok := skipNonCode(runes, i)
		if !ok {
			return false // an unterminated string or comment
		}
		if skipped > i {
			i = skipped
			continue
		}

		switch runes[i] {
		case '{', '(', '[':
			depth++
		case '}', ')', ']':
			depth--
			if depth < 0 {
				return false
			}
		}
	}

	return depth == 0
}

// skipNonCode reports the last index of the comment or string literal starting
// at i, or i itself when nothing starts there. ok is false when what starts
// there never ends, which is not a file worth counting brackets in.
func skipNonCode(runes []rune, i int) (int, bool) {
	r := runes[i]
	next := rune(0)
	if i+1 < len(runes) {
		next = runes[i+1]
	}

	switch {
	case r == '/' && next == '/':
		return skipLineComment(runes, i), true
	case r == '/' && next == '*':
		end := skipBlockComment(runes, i)
		return end, end >= 0
	case r == '"' || r == '\'':
		end := skipString(runes, i)
		return end, end >= 0
	default:
		return i, true
	}
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
	if isTripleQuote(runes, start, quote) {
		return skipTripleQuoted(runes, start, quote)
	}
	return skipSingleQuoted(runes, start, quote)
}

func isTripleQuote(runes []rune, start int, quote rune) bool {
	return start+2 < len(runes) && runes[start+1] == quote && runes[start+2] == quote
}

// skipTripleQuoted returns the index of the last quote of the closing triple,
// or -1 when the literal is unterminated.
func skipTripleQuoted(runes []rune, start int, quote rune) int {
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

// skipSingleQuoted returns the index of the closing quote, or of the newline
// that ends the line.
//
// A single-quoted Dart string cannot span lines. Treating a run-on as
// unterminated would reject a whole file over one stray apostrophe; stopping at
// the newline keeps this check to what it is for, which is brackets.
func skipSingleQuoted(runes []rune, start int, quote rune) int {
	for i := start + 1; i < len(runes); i++ {
		switch runes[i] {
		case '\\':
			i++
		case quote, '\n':
			return i
		}
	}
	return -1
}
