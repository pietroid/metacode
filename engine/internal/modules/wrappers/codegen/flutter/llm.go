package flutter

import (
	"context"
	"fmt"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/llm"
	"github.com/pietroid/metacode/engine/internal/modules/codegen/dart"
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

	prompt, err := BuildWrapperPrompt(app, plan, outDir)
	if err != nil {
		return "", fmt.Errorf("build prompt: %w", err)
	}

	raw, err := g.Client.Complete(ctx, prompt)
	if err != nil {
		return "", fmt.Errorf("llm complete: %w", err)
	}

	code, err := dart.ExtractCode(raw)
	if err != nil {
		return "", fmt.Errorf("extract dart code: %w", err)
	}

	if err := dart.Validate(code); err != nil {
		return "", fmt.Errorf("syntax validation: %w", err)
	}

	// The prompt asks for plan.ClassName, but a model is free to ignore that.
	// Rename rather than trust, so app.dart and the child wrapper references
	// stay correct and the two strategies agree on class names.
	return dart.RenameClass(code, plan.ClassName), nil
}
