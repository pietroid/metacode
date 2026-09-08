package dart

import (
	"strings"
	"testing"
)

func TestExtractCode(t *testing.T) {
	cases := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "simple fence",
			input:    "```dart\nclass A {}\n```",
			expected: "class A {}",
		},
		{
			name:     "no language tag",
			input:    "```\nclass A {}\n```",
			expected: "class A {}",
		},
		{
			name:     "explanatory text around fence",
			input:    "Here is the code:\n```dart\nclass A {}\n```\nDone.",
			expected: "class A {}",
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := ExtractCode(tc.input)
			if err != nil {
				t.Fatalf("extract failed: %v", err)
			}
			if got != tc.expected {
				t.Errorf("expected %q, got %q", tc.expected, got)
			}
		})
	}
}

func TestExtractCodeMissingFence(t *testing.T) {
	_, err := ExtractCode("no fence here")
	if err == nil {
		t.Fatal("expected error for missing fence")
	}
}

func TestValidate(t *testing.T) {
	if err := Validate("class A { const A(); }"); err != nil {
		t.Errorf("expected valid code, got %v", err)
	}
	if err := Validate("class A { const A();"); err == nil {
		t.Error("expected error for unbalanced braces")
	}
	if err := Validate("var x = 1;"); err == nil {
		t.Error("expected error for missing class")
	}
}

func TestClassName(t *testing.T) {
	cases := []struct {
		code string
		want string
	}{
		{"class HomePageWrapper extends StatelessWidget { }", "HomePageWrapper"},
		{"class _PrivateWrapper extends StatelessWidget { }", "_PrivateWrapper"},
		{"not a class", ""},
	}
	for _, tc := range cases {
		got := ClassName(tc.code)
		if got != tc.want {
			t.Errorf("ClassName(%q) = %q, want %q", tc.code, got, tc.want)
		}
	}
}

// TestValidateRejectsFragments is the check the fix loop was missing. A model
// asked to repair a wrapper once returned two bare Cubit methods, which were
// written to the wrapper file because nothing looked at them.
func TestValidateRejectsFragments(t *testing.T) {
	fragment := "void increment() => emit(CounterState(value: state.value + 1));"
	if err := Validate(fragment); err == nil {
		t.Error("expected bare methods with no class to be rejected")
	}
	if err := Validate(""); err == nil {
		t.Error("expected empty code to be rejected")
	}
}

// TestRenameClassLeavesOtherIdentifiersAlone guards the whole-word rewrite.
func TestRenameClassLeavesOtherIdentifiersAlone(t *testing.T) {
	code := "class Whatever extends StatelessWidget { const Whatever(); Whatever2 x; }"
	got := RenameClass(code, "HomePageWrapper")
	if !strings.Contains(got, "class HomePageWrapper extends StatelessWidget") {
		t.Errorf("expected the class to be renamed, got: %s", got)
	}
	if !strings.Contains(got, "Whatever2") {
		t.Errorf("expected Whatever2 to survive, got: %s", got)
	}
}
