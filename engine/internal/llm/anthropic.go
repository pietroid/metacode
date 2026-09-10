package llm

import (
	"context"
	"fmt"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"

	"github.com/pietroid/metacode/engine/internal/log"
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
func (c *anthropicClient) Complete(ctx context.Context, call Call) (Result, error) {
	client := anthropic.NewClient(c.opts...)

	maxTokens := c.cfg.MaxTokens
	if maxTokens <= 0 {
		maxTokens = DefaultMaxTokens
	}

	c.logger.Debugf("LLM request [%s]: anthropic messages model=%s max_tokens=%d prefix_len=%d prompt_len=%d",
		call.Label, c.cfg.Model, maxTokens, len(call.Prefix), len(call.Prompt))

	resp, err := client.Messages.New(ctx, anthropic.MessageNewParams{
		Model:     anthropic.Model(c.cfg.Model),
		MaxTokens: maxTokens,
		Messages:  []anthropic.MessageParam{anthropic.NewUserMessage(blocksFor(call)...)},
	})
	if err != nil {
		return Result{}, fmt.Errorf("anthropic messages: %w", err)
	}

	// A safety classifier can decline the request. That arrives as a successful
	// HTTP response with no usable content, so check it before reading blocks.
	if resp.StopReason == anthropic.StopReasonRefusal {
		return Result{}, fmt.Errorf("anthropic refused the request (category %q): %s", resp.StopDetails.Category, resp.StopDetails.Explanation)
	}

	var out string
	for _, block := range resp.Content {
		if text, ok := block.AsAny().(anthropic.TextBlock); ok {
			out += text.Text
		}
	}

	usage := Usage{
		InputTokens:      resp.Usage.InputTokens,
		OutputTokens:     resp.Usage.OutputTokens,
		CacheReadTokens:  resp.Usage.CacheReadInputTokens,
		CacheWriteTokens: resp.Usage.CacheCreationInputTokens,
	}

	c.logger.Debugf("LLM response [%s]: stop_reason=%s %s len=%d",
		call.Label, resp.StopReason, usage, len(out))

	if out == "" {
		return Result{}, fmt.Errorf("anthropic returned no text content (stop reason %q)", resp.StopReason)
	}
	return Result{Text: out, Usage: usage}, nil
}

// blocksFor splits a call into the content blocks one user message carries.
//
// A call with a prefix becomes two blocks with a cache breakpoint between
// them. The default five-minute window is the right one: the calls of a run
// are separated by a test suite, not by a coffee break, and the longer TTL
// costs twice as much to write for a lifetime nothing here needs.
//
// A breakpoint is a request to cache, not a promise: a prefix under the
// model's minimum is silently not cached, which shows up as a zero in the
// usage line rather than as an error.
func blocksFor(call Call) []anthropic.ContentBlockParamUnion {
	if call.Prefix == "" {
		return []anthropic.ContentBlockParamUnion{anthropic.NewTextBlock(call.Prompt)}
	}
	return []anthropic.ContentBlockParamUnion{
		{OfText: &anthropic.TextBlockParam{
			Text:         call.Prefix,
			CacheControl: anthropic.NewCacheControlEphemeralParam(),
		}},
		anthropic.NewTextBlock(call.Prompt),
	}
}
