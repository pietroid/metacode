package llm

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/log"
)

func TestConfigFromEnvMissingBaseURL(t *testing.T) {
	t.Setenv("METACODE_LLM_BASE_URL", "")
	t.Setenv("METACODE_LLM_API_KEY", "key")
	_, err := ConfigFromEnv()
	if err == nil || !strings.Contains(err.Error(), "METACODE_LLM_BASE_URL") {
		t.Fatalf("expected missing base url error, got %v", err)
	}
}

func TestConfigFromEnvMissingAPIKey(t *testing.T) {
	t.Setenv("METACODE_LLM_BASE_URL", "http://localhost")
	t.Setenv("METACODE_LLM_API_KEY", "")
	_, err := ConfigFromEnv()
	if err == nil || !strings.Contains(err.Error(), "METACODE_LLM_API_KEY") {
		t.Fatalf("expected missing api key error, got %v", err)
	}
}

func TestConfigFromEnvDefaultModel(t *testing.T) {
	t.Setenv("METACODE_LLM_BASE_URL", "http://localhost")
	t.Setenv("METACODE_LLM_API_KEY", "key")
	t.Setenv("METACODE_LLM_MODEL", "")
	cfg, err := ConfigFromEnv()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.Model != DefaultModel {
		t.Errorf("expected default model %q, got %q", DefaultModel, cfg.Model)
	}
}

func TestConfigFromEnvCustomModel(t *testing.T) {
	t.Setenv("METACODE_LLM_BASE_URL", "http://localhost")
	t.Setenv("METACODE_LLM_API_KEY", "key")
	t.Setenv("METACODE_LLM_MODEL", "custom-model")
	cfg, err := ConfigFromEnv()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.Model != "custom-model" {
		t.Errorf("expected custom model, got %q", cfg.Model)
	}
}

func TestCompleteSendsCorrectRequestAndExtractsContent(t *testing.T) {
	var gotAuth string
	var gotBody chatRequest
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/chat/completions" {
			t.Errorf("expected path /chat/completions, got %q", r.URL.Path)
		}
		gotAuth = r.Header.Get("Authorization")

		body, err := io.ReadAll(r.Body)
		if err != nil {
			t.Fatalf("read body: %v", err)
		}
		if err := json.Unmarshal(body, &gotBody); err != nil {
			t.Fatalf("decode body: %v", err)
		}

		resp := chatResponse{
			Choices: []choice{
				{Message: message{Role: "assistant", Content: "hello world"}},
			},
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(resp)
	}))
	defer server.Close()

	cfg := Config{BaseURL: server.URL, APIKey: "test-key", Model: "test-model"}
	client := NewClientWithHTTP(cfg, log.Nop(), server.Client())

	result, err := client.Complete(context.Background(), "say hello")
	if err != nil {
		t.Fatalf("complete failed: %v", err)
	}
	if result != "hello world" {
		t.Errorf("expected %q, got %q", "hello world", result)
	}
	if gotAuth != "Bearer test-key" {
		t.Errorf("expected auth header %q, got %q", "Bearer test-key", gotAuth)
	}
	if gotBody.Model != "test-model" {
		t.Errorf("expected model %q, got %q", "test-model", gotBody.Model)
	}
	if len(gotBody.Messages) != 1 {
		t.Fatalf("expected 1 message, got %d", len(gotBody.Messages))
	}
	if gotBody.Messages[0].Role != "user" || gotBody.Messages[0].Content != "say hello" {
		t.Errorf("unexpected message: %+v", gotBody.Messages[0])
	}
}

func TestCompleteNonOKStatus(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = w.Write([]byte("unauthorized"))
	}))
	defer server.Close()

	cfg := Config{BaseURL: server.URL, APIKey: "key", Model: "model"}
	client := NewClientWithHTTP(cfg, log.Nop(), server.Client())

	_, err := client.Complete(context.Background(), "prompt")
	if err == nil || !strings.Contains(err.Error(), "401") {
		t.Fatalf("expected 401 error, got %v", err)
	}
}

func TestCompleteDebugLogs(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resp := chatResponse{
			Choices: []choice{{Message: message{Content: "ok"}}},
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(resp)
	}))
	defer server.Close()

	var buf strings.Builder
	logger := log.New(&buf, log.DebugLevel)
	cfg := Config{BaseURL: server.URL, APIKey: "key", Model: "model"}
	client := NewClientWithHTTP(cfg, logger, server.Client())

	_, err := client.Complete(context.Background(), "prompt")
	if err != nil {
		t.Fatalf("complete failed: %v", err)
	}
	logs := buf.String()
	if !strings.Contains(logs, "llm request:") {
		t.Errorf("expected debug request log, got %q", logs)
	}
	if !strings.Contains(logs, "llm response:") {
		t.Errorf("expected debug response log, got %q", logs)
	}
}
