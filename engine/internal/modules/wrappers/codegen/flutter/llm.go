package flutter

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/llm"
	"github.com/pietroid/metacode/engine/internal/planner"
)

// LLMGenerator asks a model for each wrapper body.
type LLMGenerator struct {
	Client llm.Client
}

// NewLLMGenerator returns a Generator backed by client.
func NewLLMGenerator(client llm.Client) *LLMGenerator {
	return &LLMGenerator{Client: client}
}

// Name implements Generator.
func (g *LLMGenerator) Name() string { return "ai" }

// Generate implements Generator.
func (g *LLMGenerator) Generate(ctx context.Context, app *ir.IR, tasks []planner.Task, outDir string) error {
	return generate(ctx, app, tasks, outDir, g.body)
}

func (g *LLMGenerator) body(ctx context.Context, app *ir.IR, plan Plan, _ []Plan, outDir string) (string, error) {
	if g.Client == nil {
		return "", fmt.Errorf("no llm client configured")
	}

	prompt, err := BuildWrapperPrompt(app, PromptTask{ScenarioID: plan.Tasks[0].ScenarioID}, outDir)
	if err != nil {
		return "", fmt.Errorf("build prompt: %w", err)
	}

	raw, err := g.Client.Complete(ctx, prompt)
	if err != nil {
		return "", fmt.Errorf("llm complete: %w", err)
	}

	code, err := extractDartCode(raw)
	if err != nil {
		return "", fmt.Errorf("extract dart code: %w", err)
	}

	if err := validateDartSyntax(code); err != nil {
		return "", fmt.Errorf("syntax validation: %w", err)
	}

	// The prompt asks for plan.ClassName, but a model is free to ignore that.
	// Rename rather than trust, so app.dart and the child wrapper references
	// stay correct and the two strategies agree on class names.
	return renameWrapperClass(code, plan.ClassName), nil
}

var dartFence = regexp.MustCompile("```(?:dart)?\\s*\\n(?s)(.*?)\\n```")
var classDecl = regexp.MustCompile(`class\s+(\w+)\s+extends\s+StatelessWidget`)

func extractClassName(code string) string {
	m := classDecl.FindStringSubmatch(code)
	if len(m) < 2 {
		return ""
	}
	return m[1]
}

// renameWrapperClass rewrites the declared wrapper class, and every reference
// to it, to want.
func renameWrapperClass(code, want string) string {
	got := extractClassName(code)
	if got == "" || got == want {
		return code
	}
	return regexp.MustCompile(`\b`+regexp.QuoteMeta(got)+`\b`).ReplaceAllString(code, want)
}

func extractDartCode(raw string) (string, error) {
	matches := dartFence.FindAllStringSubmatch(raw, -1)
	if len(matches) == 0 {
		return "", fmt.Errorf("no dart code fence found")
	}
	return strings.TrimSpace(matches[len(matches)-1][1]), nil
}

func validateDartSyntax(code string) error {
	if !strings.Contains(code, "class ") {
		return fmt.Errorf("generated code missing class declaration")
	}
	if !balancedBraces(code) {
		return fmt.Errorf("generated code has unbalanced braces")
	}
	return nil
}

func balancedBraces(code string) bool {
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
