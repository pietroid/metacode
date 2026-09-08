package flutter

import (
	"context"
	"fmt"
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
	prompts    []string
	response   string
}

// promptFor returns the prompt built for the wrapper of the named widget.
func (m *mockClient) promptFor(widget string) string {
	needle := fmt.Sprintf("wrapper widget for %q", widget)
	for _, p := range m.prompts {
		if strings.Contains(p, needle) {
			return p
		}
	}
	return ""
}

func (m *mockClient) Complete(ctx context.Context, prompt string) (string, error) {
	m.lastPrompt = prompt
	m.prompts = append(m.prompts, prompt)
	resp := m.response
	if resp == "" {
		class := "IncrementButtonWrapper"
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
									"incrementButton",
								},
							},
						},
					},
				},
				"incrementButton": map[string]any{
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
					"when":  "incrementButton.onPressed",
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

	for _, name := range []string{"lib/wrappers/increment_button_wrapper.dart", "lib/wrappers/home_page_wrapper.dart"} {
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

// TestPageWrapperPromptCoversWholeSubtree pins the fix for a page that came
// back with one button wired and the other dead: the page wrapper is the only
// widget in the composed tree, so its prompt has to carry every scenario the
// page is responsible for, not the one scenario its first planner task
// happened to name.
func TestPageWrapperPromptCoversWholeSubtree(t *testing.T) {
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

	prompt := mock.promptFor("homePage")
	if prompt == "" {
		t.Fatalf("no prompt was built for homePage, got %d prompts", len(mock.prompts))
	}

	for _, want := range []string{
		// The page's own scenario.
		"homePage.counterValue",
		// The scenario of the button the page embeds.
		"incrementButton.onPressed",
		// The resolved binding, so the model calls the Cubit rather than emit.
		"incrementButton.onPressed -> counterStore.increment",
		// The generated code it must compose.
		"class CounterCubit",
		"class HomePage",
	} {
		if !strings.Contains(prompt, want) {
			t.Errorf("expected the homePage prompt to contain %q, got:\n%s", want, prompt)
		}
	}
}

// Ensure mockClient implements llm.Client at compile time.
var _ llm.Client = (*mockClient)(nil)
