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

// counterResolvedIR builds the counter app and resolves it, so the symbol table
// carries the events declared in behaviors.yaml. Generation in the real pipeline
// always runs after resolution.
func counterResolvedIR(t *testing.T) *ir.IR {
	t.Helper()
	app, err := ir.Build(counterAppSpecs())
	if err != nil {
		t.Fatalf("build ir: %v", err)
	}
	if err := app.Resolve(catalog.New()); err != nil {
		t.Fatalf("resolve: %v", err)
	}
	return &app
}

func generateAndRead(t *testing.T, app *ir.IR, rel string) string {
	t.Helper()
	dir := t.TempDir()
	if err := Generate(app, catalog.New(), dir); err != nil {
		t.Fatalf("generate widgets failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, filepath.FromSlash(rel)))
	if err != nil {
		t.Fatalf("read %s: %v", rel, err)
	}
	return string(data)
}

// TestDeclaredEventBecomesConstructorParameter is the regression test for a
// dumb widget that could not be wired at all: counterButton.onPressed is
// declared in behaviors.yaml, but the button was generated with
// `onPressed: null`, so it rendered permanently disabled and no wrapper — LLM
// or deterministic — could make a tap reach the Cubit.
func TestDeclaredEventBecomesConstructorParameter(t *testing.T) {
	content := generateAndRead(t, counterResolvedIR(t), "lib/widgets/counter_button.dart")

	for _, want := range []string{
		"const CounterButton({super.key, this.onPressed});",
		"final VoidCallback? onPressed;",
		"onPressed: onPressed",
	} {
		if !strings.Contains(content, want) {
			t.Errorf("expected %q, got:\n%s", want, content)
		}
	}
	if strings.Contains(content, "onPressed: null") {
		t.Errorf("expected the button not to be hard-disabled, got:\n%s", content)
	}
}

// TestParentForwardsChildEvents covers composition: a page that embeds a widget
// with a declared event must forward that event, or the page can only ever be
// rendered with a dead child.
func TestParentForwardsChildEvents(t *testing.T) {
	content := generateAndRead(t, counterResolvedIR(t), "lib/pages/home_page.dart")

	for _, want := range []string{
		"this.counterButtonOnPressed",
		"final VoidCallback? counterButtonOnPressed;",
		"CounterButton(onPressed: counterButtonOnPressed)",
	} {
		if !strings.Contains(content, want) {
			t.Errorf("expected %q, got:\n%s", want, content)
		}
	}
}

// TestUndeclaredEventStaysDisabled keeps the parameter tied to the specs: a
// button no behavior refers to has nothing to wire, and a nullable callback
// nobody passes would only widen the API for no reason.
func TestUndeclaredEventStaysDisabled(t *testing.T) {
	specs := counterAppSpecs()
	specs.Behaviors = map[string]any{}

	app, err := ir.Build(specs)
	if err != nil {
		t.Fatalf("build ir: %v", err)
	}
	if err := app.Resolve(catalog.New()); err != nil {
		t.Fatalf("resolve: %v", err)
	}

	content := generateAndRead(t, &app, "lib/widgets/counter_button.dart")
	if !strings.Contains(content, "onPressed: null") {
		t.Errorf("expected onPressed: null with no behavior declared, got:\n%s", content)
	}
	if strings.Contains(content, "VoidCallback") {
		t.Errorf("expected no callback parameter with no behavior declared, got:\n%s", content)
	}
}
