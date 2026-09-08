package llm

import (
	"fmt"
	"os"
)

// Provider selects which backend the LLM client talks to.
type Provider string

const (
	// ProviderAnthropic uses the official Anthropic Messages API via the Go SDK.
	ProviderAnthropic Provider = "anthropic"
	// ProviderOpenAI uses any OpenAI-compatible /chat/completions endpoint.
	ProviderOpenAI Provider = "openai"
)

// DefaultProvider is used when METACODE_LLM_PROVIDER is not set.
const DefaultProvider = ProviderAnthropic

// DefaultAnthropicModel is used when no model is configured for Anthropic.
const DefaultAnthropicModel = "claude-opus-5"

// DefaultOpenAIModel is used when no model is configured for the
// OpenAI-compatible provider.
const DefaultOpenAIModel = "opencode-go/kimi-k2.7-code"

// DefaultMaxTokens is the response cap for a single generation. Wrapper and fix
// generations are a single Dart file, so this is generous.
const DefaultMaxTokens = 16000

// Config holds the runtime configuration for the LLM client.
type Config struct {
	Provider  Provider
	BaseURL   string // OpenAI-compatible only; optional override for Anthropic
	APIKey    string
	Model     string
	MaxTokens int64
}

// ConfigFromEnv reads the LLM configuration from environment variables.
//
// Anthropic (the default provider):
//
//	ANTHROPIC_API_KEY        required
//	METACODE_LLM_MODEL       optional, defaults to claude-opus-5
//
// OpenAI-compatible (METACODE_LLM_PROVIDER=openai):
//
//	METACODE_LLM_BASE_URL    required
//	METACODE_LLM_API_KEY     required
//	METACODE_LLM_MODEL       optional
//
// METACODE_LLM_API_KEY is also accepted for Anthropic, so a single variable can
// drive either provider.
func ConfigFromEnv() (Config, error) {
	cfg := Config{
		Provider:  Provider(os.Getenv("METACODE_LLM_PROVIDER")),
		BaseURL:   os.Getenv("METACODE_LLM_BASE_URL"),
		Model:     os.Getenv("METACODE_LLM_MODEL"),
		MaxTokens: DefaultMaxTokens,
	}
	if cfg.Provider == "" {
		cfg.Provider = DefaultProvider
	}

	switch cfg.Provider {
	case ProviderAnthropic:
		cfg.APIKey = firstNonEmpty(os.Getenv("ANTHROPIC_API_KEY"), os.Getenv("METACODE_LLM_API_KEY"))
		if cfg.APIKey == "" {
			return Config{}, fmt.Errorf("missing required environment variable ANTHROPIC_API_KEY")
		}
		if cfg.Model == "" {
			cfg.Model = DefaultAnthropicModel
		}
	case ProviderOpenAI:
		cfg.APIKey = os.Getenv("METACODE_LLM_API_KEY")
		if cfg.BaseURL == "" {
			return Config{}, fmt.Errorf("missing required environment variable METACODE_LLM_BASE_URL")
		}
		if cfg.APIKey == "" {
			return Config{}, fmt.Errorf("missing required environment variable METACODE_LLM_API_KEY")
		}
		if cfg.Model == "" {
			cfg.Model = DefaultOpenAIModel
		}
	default:
		return Config{}, fmt.Errorf("unknown METACODE_LLM_PROVIDER %q (expected %q or %q)", cfg.Provider, ProviderAnthropic, ProviderOpenAI)
	}

	return cfg, nil
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if v != "" {
			return v
		}
	}
	return ""
}
