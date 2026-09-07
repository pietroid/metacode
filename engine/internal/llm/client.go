// Package llm provides a thin HTTP client for OpenAI-compatible chat
// completion endpoints.
package llm

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/pietroid/metacode/engine/internal/core/log"
)

// Client is the abstract interface implemented by the LLM client.
// It exists so callers can swap in caching, retry, streaming, or test doubles.
type Client interface {
	Complete(ctx context.Context, prompt string) (string, error)
}

// NewClient creates a concrete Client from cfg and logger.
func NewClient(cfg Config, logger log.Logger) Client {
	if logger == nil {
		logger = log.Nop()
	}
	return &client{
		cfg:    cfg,
		http:   http.DefaultClient,
		logger: logger,
	}
}

type client struct {
	cfg    Config
	http   *http.Client
	logger log.Logger
}

type chatRequest struct {
	Model    string    `json:"model"`
	Messages []message `json:"messages"`
}

type message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatResponse struct {
	Choices []choice `json:"choices"`
}

type choice struct {
	Message message `json:"message"`
}

// Complete sends a single user message to the configured chat completions
// endpoint and returns the assistant message content.
func (c *client) Complete(ctx context.Context, prompt string) (string, error) {
	reqBody := chatRequest{
		Model: c.cfg.Model,
		Messages: []message{
			{Role: "user", Content: prompt},
		},
	}
	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("marshal request: %w", err)
	}

	c.logger.Debugf("llm request: POST %s/chat/completions model=%s", c.cfg.BaseURL, c.cfg.Model)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.cfg.BaseURL+"/chat/completions", bytes.NewReader(jsonBody))
	if err != nil {
		return "", fmt.Errorf("create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.cfg.APIKey)

	resp, err := c.http.Do(req)
	if err != nil {
		return "", fmt.Errorf("do request: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("read response body: %w", err)
	}

	c.logger.Debugf("llm response: status=%d len=%d", resp.StatusCode, len(respBody))

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("unexpected status %d: %s", resp.StatusCode, string(respBody))
	}

	var parsed chatResponse
	if err := json.Unmarshal(respBody, &parsed); err != nil {
		return "", fmt.Errorf("decode response: %w", err)
	}
	if len(parsed.Choices) == 0 {
		return "", fmt.Errorf("empty choices in response")
	}
	return parsed.Choices[0].Message.Content, nil
}

// NewClientWithHTTP creates a client using a custom HTTP client. It is used
// mainly by tests that want to point the client at a mock server.
func NewClientWithHTTP(cfg Config, logger log.Logger, httpClient *http.Client) Client {
	if logger == nil {
		logger = log.Nop()
	}
	if httpClient == nil {
		httpClient = http.DefaultClient
	}
	return &client{
		cfg:    cfg,
		http:   httpClient,
		logger: logger,
	}
}
