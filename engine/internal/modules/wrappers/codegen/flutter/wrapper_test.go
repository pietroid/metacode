package flutter

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/llm"
	dataflutter "github.com/pietroid/metacode/engine/internal/modules/data/codegen/flutter"
	projectflutter "github.com/pietroid/metacode/engine/internal/modules/project/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
	uiflutter "github.com/pietroid/metacode/engine/internal/modules/ui/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/planner"
)

type mockClient struct {
	lastPrompt string
	response   string
}

func (m *mockClient) Complete(ctx context.Context, prompt string) (string, error) {
	m.lastPrompt = prompt
	resp := m.response
	if resp == "" {
		class := "CounterButtonWrapper"
		if strings.Contains(prompt, "homePage") {
			class = "HomePageWrapper"
		}
		resp = "```dart\nclass " + class + " extends StatelessWidget {\n  const " + class + "({super.key});\n  @override\n  Widget build(BuildContext context) {\n    return Container();\n  }\n}\n```"
	}
	return resp, nil
}

func counterAppFullIR() *ir.IR {
	raw := spec.RawSpecs{
		Project: map[string]any{
			"name":        "counter_app",
			"description": "A simple counter app",
		},
		Data: map[string]any{
			"stores": map[string]any{
				"counterStore": map[string]any{
					"value":        "int",
					"initialValue": 0,
					"strategy":     "ephemeral",
				},
			},
		},
		UI: map[string]any{
			"widgets": map[string]any{
				"homePage": map[string]any{
					"scaffold": map[string]any{
						"appBar": map[string]any{
							"title": "Counter App",
						},
						"body": map[string]any{
							"center": map[string]any{
								"column": []any{
									map[string]any{"text": "counterValue"},
									"counterButton",
								},
							},
						},
					},
				},
				"counterButton": map[string]any{
					"elevatedButton": map[string]any{
						"child": "Increment",
					},
				},
			},
		},
		Behaviors: map[string]any{
			"counterStore": map[string]any{
				"increments from 0": map[string]any{
					"given": "counterStore.value is 0",
					"when":  "counterButton.onPressed",
					"then":  "counterStore.value should be 1",
				},
				"Show counter value on the home page": map[string]any{
					"given": "counterStore.value = 5",
					"when":  "",
					"then":  "homePage.counterValue = 5",
				},
			},
		},
	}
	app, err := ir.Build(raw)
	if err != nil {
		panic(err)
	}
	if err := app.Resolve(catalog.New()); err != nil {
		panic(err)
	}
	return &app
}

func setupGeneratedFiles(t *testing.T, app *ir.IR) string {
	t.Helper()
	dir := t.TempDir()

	if err := projectflutter.Generate(app, dir); err != nil {
		t.Fatalf("project generation: %v", err)
	}
	if err := dataflutter.Generate(app, dir); err != nil {
		t.Fatalf("store generation: %v", err)
	}
	if err := uiflutter.Generate(app, catalog.New(), dir); err != nil {
		t.Fatalf("widget generation: %v", err)
	}
	return dir
}

func TestGenerateWrappersWritesFiles(t *testing.T) {
	app := counterAppFullIR()
	dir := setupGeneratedFiles(t, app)

	tasks, err := planner.Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	mock := &mockClient{}

	if err := NewLLMGenerator(mock).Generate(context.Background(), app, tasks, dir); err != nil {
		t.Fatalf("generate wrappers failed: %v", err)
	}

	for _, name := range []string{"lib/wrappers/counter_button_wrapper.dart", "lib/wrappers/home_page_wrapper.dart"} {
		path := filepath.Join(dir, name)
		if _, err := os.Stat(path); err != nil {
			t.Errorf("expected %s to exist: %v", name, err)
		}
	}

	appDart, err := os.ReadFile(filepath.Join(dir, "lib", "app.dart"))
	if err != nil {
		t.Fatalf("read app.dart: %v", err)
	}
	content := string(appDart)
	if !strings.Contains(content, "HomePageWrapper") {
		t.Errorf("expected app.dart to reference HomePageWrapper, got:\n%s", content)
	}
	if !strings.Contains(content, "BlocProvider") {
		t.Errorf("expected app.dart to contain BlocProvider, got:\n%s", content)
	}
	if !strings.Contains(content, "import 'package:flutter_bloc/flutter_bloc.dart';") {
		t.Errorf("expected app.dart to import flutter_bloc, got:\n%s", content)
	}
}

func TestGenerateWrappersPromptContainsBehaviorAndCode(t *testing.T) {
	app := counterAppFullIR()
	dir := setupGeneratedFiles(t, app)

	tasks, err := planner.Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	mock := &mockClient{
		response: "```dart\nclass CounterButtonWrapper extends StatelessWidget {\n  const CounterButtonWrapper({super.key});\n  @override\n  Widget build(BuildContext context) {\n    return Container();\n  }\n}\n```",
	}

	if err := NewLLMGenerator(mock).Generate(context.Background(), app, tasks, dir); err != nil {
		t.Fatalf("generate wrappers failed: %v", err)
	}

	if !strings.Contains(mock.lastPrompt, "homePage.counterValue") {
		t.Errorf("expected prompt to contain behavior assertion, got:\n%s", mock.lastPrompt)
	}
	if !strings.Contains(mock.lastPrompt, "class CounterCubit") {
		t.Errorf("expected prompt to contain cubit code, got:\n%s", mock.lastPrompt)
	}
	if !strings.Contains(mock.lastPrompt, "class HomePage") {
		t.Errorf("expected prompt to contain dumb widget code, got:\n%s", mock.lastPrompt)
	}
}

func TestExtractDartCode(t *testing.T) {
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
			got, err := extractDartCode(tc.input)
			if err != nil {
				t.Fatalf("extract failed: %v", err)
			}
			if got != tc.expected {
				t.Errorf("expected %q, got %q", tc.expected, got)
			}
		})
	}
}

func TestExtractDartCodeMissingFence(t *testing.T) {
	_, err := extractDartCode("no fence here")
	if err == nil {
		t.Fatal("expected error for missing fence")
	}
}

func TestValidateDartSyntax(t *testing.T) {
	if err := validateDartSyntax("class A { const A(); }"); err != nil {
		t.Errorf("expected valid code, got %v", err)
	}
	if err := validateDartSyntax("class A { const A();"); err == nil {
		t.Error("expected error for unbalanced braces")
	}
	if err := validateDartSyntax("var x = 1;"); err == nil {
		t.Error("expected error for missing class")
	}
}

func TestExtractClassName(t *testing.T) {
	cases := []struct {
		code string
		want string
	}{
		{"class HomePageWrapper extends StatelessWidget { }", "HomePageWrapper"},
		{"class _PrivateWrapper extends StatelessWidget { }", "_PrivateWrapper"},
		{"not a class", ""},
	}
	for _, tc := range cases {
		got := extractClassName(tc.code)
		if got != tc.want {
			t.Errorf("extractClassName(%q) = %q, want %q", tc.code, got, tc.want)
		}
	}
}

// Ensure mockClient implements llm.Client at compile time.
var _ llm.Client = (*mockClient)(nil)
