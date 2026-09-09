package uiflutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/build"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

func counterIR() *model.App {
	app, err := build.App(counterAppSpecs())
	if err != nil {
		panic(err)
	}
	return &app
}

func TestGenerateWidgetsCounterApp(t *testing.T) {
	dir := t.TempDir()
	app := counterIR()
	if err := Generate(app, catalog.Default(), dir); err != nil {
		t.Fatalf("generate widgets failed: %v", err)
	}

	for _, name := range []string{"lib/pages/home_page.dart", "lib/widgets/increment_button.dart"} {
		path := filepath.Join(dir, name)
		if _, err := os.Stat(path); err != nil {
			t.Errorf("expected %s to exist: %v", name, err)
		}
	}
}

func TestHomePageContents(t *testing.T) {
	dir := t.TempDir()
	app := counterIR()
	if err := Generate(app, catalog.Default(), dir); err != nil {
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
	if !strings.Contains(content, "const IncrementButton()") {
		t.Errorf("expected IncrementButton reference, got:\n%s", content)
	}
	if !strings.Contains(content, "import '../widgets/increment_button.dart'") {
		t.Errorf("expected import for increment_button.dart, got:\n%s", content)
	}
	if !strings.Contains(content, "Key('homePage')") {
		t.Errorf("expected Key('homePage'), got:\n%s", content)
	}
}

func TestIncrementButtonContents(t *testing.T) {
	dir := t.TempDir()
	app := counterIR()
	if err := Generate(app, catalog.Default(), dir); err != nil {
		t.Fatalf("generate widgets failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, "lib", "widgets", "increment_button.dart"))
	if err != nil {
		t.Fatalf("read increment_button.dart: %v", err)
	}
	content := string(data)
	if !strings.Contains(content, "class IncrementButton extends StatelessWidget") {
		t.Errorf("expected IncrementButton class, got:\n%s", content)
	}
	if !strings.Contains(content, "ElevatedButton(") {
		t.Errorf("expected ElevatedButton, got:\n%s", content)
	}
	if !strings.Contains(content, "const Text('Increment')") {
		t.Errorf("expected const Text('Increment'), got:\n%s", content)
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

// counterResolvedIR builds the counter app and resolves it, so the symbol table
// carries the events declared in behaviors.yaml. Generation in the real pipeline
// always runs after resolution.
func counterResolvedIR(t *testing.T) *model.App {
	t.Helper()
	app, err := build.App(counterAppSpecs())
	if err != nil {
		t.Fatalf("build ir: %v", err)
	}
	if err := build.Resolve(&app, catalog.Default()); err != nil {
		t.Fatalf("resolve: %v", err)
	}
	return &app
}

func generateAndRead(t *testing.T, app *model.App, rel string) string {
	t.Helper()
	dir := t.TempDir()
	if err := Generate(app, catalog.Default(), dir); err != nil {
		t.Fatalf("generate widgets failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, filepath.FromSlash(rel)))
	if err != nil {
		t.Fatalf("read %s: %v", rel, err)
	}
	return string(data)
}

// TestDeclaredEventBecomesConstructorParameter is the regression test for a
// dumb widget that could not be wired at all: incrementButton.onPressed is
// declared in behaviors.yaml, but the button was generated with
// `onPressed: null`, so it rendered permanently disabled and no wrapper — LLM
// or deterministic — could make a tap reach the Cubit.
func TestDeclaredEventBecomesConstructorParameter(t *testing.T) {
	content := generateAndRead(t, counterResolvedIR(t), "lib/widgets/increment_button.dart")

	for _, want := range []string{
		"const IncrementButton({super.key, this.onPressed});",
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

// TestWiredChildBecomesASlot covers composition: a child with something to wire
// has a wrapper of its own, so the page takes it as a Widget parameter and
// renders it as given. The page used to declare a callback per child event and
// build the child itself, which is what let one freehand wrapper at the top
// decide the shape of the whole tree.
func TestWiredChildBecomesASlot(t *testing.T) {
	content := generateAndRead(t, counterResolvedIR(t), "lib/pages/home_page.dart")

	for _, want := range []string{
		"required this.incrementButton",
		"final Widget incrementButton;",
		"incrementButton",
	} {
		if !strings.Contains(content, want) {
			t.Errorf("expected %q, got:\n%s", want, content)
		}
	}
	for _, unwanted := range []string{"incrementButtonOnPressed", "IncrementButton(", "increment_button.dart"} {
		if strings.Contains(content, unwanted) {
			t.Errorf("expected the page not to build or forward to its wired child, found %q in:\n%s", unwanted, content)
		}
	}
}

// TestUndeclaredEventStaysDisabled keeps the parameter tied to the specs: a
// button no behavior refers to has nothing to wire, and a nullable callback
// nobody passes would only widen the API for no reason.
func TestUndeclaredEventStaysDisabled(t *testing.T) {
	specs := counterAppSpecs()
	specs.Behaviors = map[string]any{}

	app, err := build.App(specs)
	if err != nil {
		t.Fatalf("build ir: %v", err)
	}
	if err := build.Resolve(&app, catalog.Default()); err != nil {
		t.Fatalf("resolve: %v", err)
	}

	content := generateAndRead(t, &app, "lib/widgets/increment_button.dart")
	if !strings.Contains(content, "onPressed: null") {
		t.Errorf("expected onPressed: null with no behavior declared, got:\n%s", content)
	}
	if strings.Contains(content, "VoidCallback") {
		t.Errorf("expected no callback parameter with no behavior declared, got:\n%s", content)
	}
}

func TestRenderIconProp(t *testing.T) {
	r := &renderer{catalog: catalog.Default()}
	if got := r.renderIconProp("icon", "icons.add"); got != "Icons.add" {
		t.Errorf("icon widget renders %q, want Icons.add", got)
	}
	if got := r.renderIconProp("iconButton", "icons.hidden"); got != "icon: const Icon(Icons.visibility_off)" {
		t.Errorf("iconButton renders %q", got)
	}
	if got := r.renderIconProp("icon", "add"); got != "" {
		t.Errorf("an unqualified name renders %q, want empty", got)
	}
}

func TestForwardedVariablesReachTheReferencedWidget(t *testing.T) {
	symbols := model.NewSymbolTable()
	symbols.Widgets["taskCheckbox"] = model.UIComponent{
		Name:      "taskCheckbox",
		Variables: []model.Variable{{Name: "taskDone", Type: "boolean"}},
	}
	got := forwardedVariables([]string{"taskCheckbox"}, symbols)
	if len(got["taskCheckbox"]) != 1 || got["taskCheckbox"][0].Name != "taskDone" {
		t.Errorf("expected taskDone forwarded, got %+v", got)
	}
}
