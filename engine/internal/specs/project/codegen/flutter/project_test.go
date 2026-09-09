package projectflutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/build"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/spec"
)

func counterIR() *model.App {
	app, err := build.App(counterAppSpecs())
	if err != nil {
		panic(err)
	}
	return &app
}

func TestGenerateProjectCreatesFiles(t *testing.T) {
	dir := t.TempDir()
	if err := Generate(counterIR(), dir); err != nil {
		t.Fatalf("generate project failed: %v", err)
	}

	for _, name := range []string{"pubspec.yaml", "lib/main.dart", "lib/app.dart"} {
		path := filepath.Join(dir, name)
		if _, err := os.Stat(path); err != nil {
			t.Errorf("expected %s to exist: %v", name, err)
		}
	}
}

func TestPubspecPackageName(t *testing.T) {
	dir := t.TempDir()
	if err := Generate(counterIR(), dir); err != nil {
		t.Fatalf("generate project failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, "pubspec.yaml"))
	if err != nil {
		t.Fatalf("read pubspec: %v", err)
	}
	if !strings.Contains(string(data), "name: counter_app") {
		t.Errorf("expected pubspec name counter_app, got:\n%s", string(data))
	}
}

func TestMainDart(t *testing.T) {
	dir := t.TempDir()
	if err := Generate(counterIR(), dir); err != nil {
		t.Fatalf("generate project failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, "lib", "main.dart"))
	if err != nil {
		t.Fatalf("read main.dart: %v", err)
	}
	if !strings.Contains(string(data), "runApp(const MyApp())") {
		t.Errorf("expected runApp(const MyApp()) in main.dart, got:\n%s", string(data))
	}
}

func TestAppDartHomePage(t *testing.T) {
	dir := t.TempDir()
	if err := Generate(counterIR(), dir); err != nil {
		t.Fatalf("generate project failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, "lib", "app.dart"))
	if err != nil {
		t.Fatalf("read app.dart: %v", err)
	}
	content := string(data)
	if !strings.Contains(content, "home: const HomePage(") {
		t.Errorf("expected home: const HomePage(...) in app.dart, got:\n%s", content)
	}
	if !strings.Contains(content, "import 'pages/home_page.dart'") {
		t.Errorf("expected import for home_page.dart, got:\n%s", content)
	}
}

// counterAppSpecs mirrors the counter app fixtures used by the IR behaviorflutter.
func counterAppSpecs() spec.RawSpecs {
	return spec.RawSpecs{
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
					"given": map[string]any{"counterStore.value": 0},
					"when":  "incrementButton.onPressed",
					"then":  "counterStore.value should be 1",
				},
			},
		},
	}
}

// TestGenerateLaunchConfig guards the dot-directory: templates are embedded
// with all: precisely so .vscode ships, and a plain //go:embed would drop it
// without failing anything.
func TestGenerateLaunchConfig(t *testing.T) {
	dir := t.TempDir()
	if err := Generate(counterIR(), dir); err != nil {
		t.Fatalf("generate project failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, ".vscode", "launch.json"))
	if err != nil {
		t.Fatalf("read launch.json: %v", err)
	}
	content := string(data)
	for _, want := range []string{`"name": "counter_app"`, `"program": "lib/main.dart"`, `"flutterMode": "profile"`} {
		if !strings.Contains(content, want) {
			t.Errorf("expected launch.json to contain %q, got:\n%s", want, content)
		}
	}
}
