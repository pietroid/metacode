package flutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
)

func counterIR() *ir.IR {
	app, err := ir.Build(counterAppSpecs())
	if err != nil {
		panic(err)
	}
	return &app
}

func TestGenerateWidgetsCounterApp(t *testing.T) {
	dir := t.TempDir()
	app := counterIR()
	if err := Generate(app, catalog.New(), dir); err != nil {
		t.Fatalf("generate widgets failed: %v", err)
	}

	for _, name := range []string{"lib/pages/home_page.dart", "lib/widgets/counter_button.dart"} {
		path := filepath.Join(dir, name)
		if _, err := os.Stat(path); err != nil {
			t.Errorf("expected %s to exist: %v", name, err)
		}
	}
}

func TestHomePageContents(t *testing.T) {
	dir := t.TempDir()
	app := counterIR()
	if err := Generate(app, catalog.New(), dir); err != nil {
		t.Fatalf("generate widgets failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, "lib", "pages", "home_page.dart"))
	if err != nil {
		t.Fatalf("read home_page.dart: %v", err)
	}
	content := string(data)
	if !strings.Contains(content, "class HomePage extends StatelessWidget") {
		t.Errorf("expected HomePage class, got:\n%s", content)
	}
	if !strings.Contains(content, "required this.counterValue") {
		t.Errorf("expected required counterValue parameter, got:\n%s", content)
	}
	if !strings.Contains(content, "final String counterValue") {
		t.Errorf("expected final String counterValue field, got:\n%s", content)
	}
	if !strings.Contains(content, "Text(counterValue)") {
		t.Errorf("expected Text(counterValue), got:\n%s", content)
	}
	if !strings.Contains(content, "const CounterButton()") {
		t.Errorf("expected CounterButton reference, got:\n%s", content)
	}
	if !strings.Contains(content, "import '../widgets/counter_button.dart'") {
		t.Errorf("expected import for counter_button.dart, got:\n%s", content)
	}
	if !strings.Contains(content, "Key('homePage')") {
		t.Errorf("expected Key('homePage'), got:\n%s", content)
	}
}

func TestCounterButtonContents(t *testing.T) {
	dir := t.TempDir()
	app := counterIR()
	if err := Generate(app, catalog.New(), dir); err != nil {
		t.Fatalf("generate widgets failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, "lib", "widgets", "counter_button.dart"))
	if err != nil {
		t.Fatalf("read counter_button.dart: %v", err)
	}
	content := string(data)
	if !strings.Contains(content, "class CounterButton extends StatelessWidget") {
		t.Errorf("expected CounterButton class, got:\n%s", content)
	}
	if !strings.Contains(content, "ElevatedButton(") {
		t.Errorf("expected ElevatedButton, got:\n%s", content)
	}
	if !strings.Contains(content, "const Text('Increment')") {
		t.Errorf("expected const Text('Increment'), got:\n%s", content)
	}
}

func TestIsPage(t *testing.T) {
	if !isPage("homePage") {
		t.Error("expected homePage to be a page")
	}
	if !isPage("settingsPage") {
		t.Error("expected settingsPage to be a page")
	}
	if isPage("counterButton") {
		t.Error("expected counterButton to be a widget")
	}
}

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
			},
		},
	}
}
