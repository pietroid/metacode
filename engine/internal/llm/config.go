package llm

import (
	"fmt"
	"os"
)

// DefaultModel is used when METACODE_LLM_MODEL is not set.
const DefaultModel = "opencode-go/kimi-k2.7-code"

// Config holds the runtime configuration for the LLM client.
type Config struct {
	BaseURL string
	APIKey  string
	Model   string
}

// ConfigFromEnv reads the LLM configuration from environment variables.
// METACODE_LLM_BASE_URL and METACODE_LLM_API_KEY are required.
func ConfigFromEnv() (Config, error) {
	cfg := Config{
		BaseURL: os.Getenv("METACODE_LLM_BASE_URL"),
		APIKey:  os.Getenv("METACODE_LLM_API_KEY"),
		Model:   os.Getenv("METACODE_LLM_MODEL"),
	}
	if cfg.BaseURL == "" {
		return Config{}, fmt.Errorf("missing required environment variable METACODE_LLM_BASE_URL")
	}
	if cfg.APIKey == "" {
		return Config{}, fmt.Errorf("missing required environment variable METACODE_LLM_API_KEY")
	}
	if cfg.Model == "" {
		cfg.Model = DefaultModel
	}
	return cfg, nil
}
