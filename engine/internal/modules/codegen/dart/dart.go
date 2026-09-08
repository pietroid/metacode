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

// Balanced reports whether brackets outside string literals are balanced.
func Balanced(code string) bool {
	depth := 0
	inString := false
	stringChar := rune(0)
	for i, r := range code {
		if inString {
			if r == stringChar {
				inString = false
			} else if r == '\\' && i+1 < len(code) {
				// Skip escaped character.
				_ = code[i+1]
			}
			continue
		}
		if r == '"' || r == '\'' {
			inString = true
			stringChar = r
			continue
		}
		switch r {
		case '{', '(', '[':
			depth++
		case '}', ')', ']':
			depth--
			if depth < 0 {
				return false
			}
		}
	}
	return depth == 0 && !inString
}
