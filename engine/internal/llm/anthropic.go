package llm

import (
	"context"
	"fmt"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"

	"github.com/pietroid/metacode/engine/internal/core/log"
)

// anthropicClient talks to the Anthropic Messages API through the official Go
// SDK.
//
// It holds request options rather than a constructed client so the SDK's client
// type is never named here. Constructing the client per call is cheap: a run
// makes a handful of requests, not a stream of them.
type anthropicClient struct {
	cfg    Config
	opts   []option.RequestOption
	logger log.Logger
}

func newAnthropicClient(cfg Config, logger log.Logger) Client {
	opts := []option.RequestOption{option.WithAPIKey(cfg.APIKey)}
	if cfg.BaseURL != "" {
		opts = append(opts, option.WithBaseURL(cfg.BaseURL))
	}
	return &anthropicClient{cfg: cfg, opts: opts, logger: logger}
}

// Complete sends a single user message and returns the concatenated text of the
// response.
//
// Thinking is left unset on purpose. Claude Opus 5 runs adaptive thinking by
// default, which is what we want for code generation, and not naming the
// parameter keeps this call compatible with models that reject an explicit
// thinking config.
func (c *anthropicClient) Complete(ctx context.Context, call Call) (string, error) {
	client := anthropic.NewClient(c.opts...)
	prompt := call.Prompt

	maxTokens := c.cfg.MaxTokens
	if maxTokens <= 0 {
		maxTokens = DefaultMaxTokens
	}

	c.logger.Debugf("llm request [%s]: anthropic messages model=%s max_tokens=%d prompt_len=%d", call.Label, c.cfg.Model, maxTokens, len(prompt))

	resp, err := client.Messages.New(ctx, anthropic.MessageNewParams{
		Model:     anthropic.Model(c.cfg.Model),
		MaxTokens: maxTokens,
		Messages: []anthropic.MessageParam{
			anthropic.NewUserMessage(anthropic.NewTextBlock(prompt)),
		},
	})
	if err != nil {
		return "", fmt.Errorf("anthropic messages: %w", err)
	}

	// A safety classifier can decline the request. That arrives as a successful
	// HTTP response with no usable content, so check it before reading blocks.
	if resp.StopReason == anthropic.StopReasonRefusal {
		return "", fmt.Errorf("anthropic refused the request (category %q): %s", resp.StopDetails.Category, resp.StopDetails.Explanation)
	}

	var out string
	for _, block := range resp.Content {
		if text, ok := block.AsAny().(anthropic.TextBlock); ok {
			out += text.Text
		}
	}

	c.logger.Debugf("llm response [%s]: stop_reason=%s input_tokens=%d output_tokens=%d len=%d",
		call.Label, resp.StopReason, resp.Usage.InputTokens, resp.Usage.OutputTokens, len(out))

	if out == "" {
		return "", fmt.Errorf("anthropic returned no text content (stop reason %q)", resp.StopReason)
	}
	return out, nil
}
