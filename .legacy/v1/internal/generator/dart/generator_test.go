package dart

import (
	"strings"
	"testing"

	"metacode/internal/graph"
	"metacode/internal/spec"
)

func TestGenerateCounterExample(t *testing.T) {
	set, err := spec.LoadSpecs("../../../metacode")
	if err != nil {
		t.Fatalf("load specs: %v", err)
	}
	g, err := graph.Build(set)
	if err != nil {
		t.Fatalf("build graph: %v", err)
	}

	files, err := GenerateFiles(g)
	if err != nil {
		t.Fatalf("generate files: %v", err)
	}

	mustContain(t, files, "pubspec.yaml", "name: counter_example")
	mustContain(t, files, "lib/main.dart", "class MyApp")
	mustContain(t, files, "lib/models/counter_store.dart", "class CounterStore extends ChangeNotifier")
	mustContain(t, files, "lib/models/counter_store.dart", "void increment()")
	mustContain(t, files, "lib/pages/home_page.dart", "class HomePage extends StatelessWidget")
	mustContain(t, files, "lib/pages/counter_button.dart", "class CounterButton extends StatelessWidget")
	mustContain(t, files, "lib/pages/counter_button.dart", "FloatingActionButton")
	mustContain(t, files, "lib/pages/home_page.dart", "ListenableBuilder")
	mustContain(t, files, "test/metacode_test.dart", "testWidgets")
	mustContain(t, files, "test/metacode_test.dart", "find.text('5')")
	mustContain(t, files, "test/metacode_test.dart", "counterStore.increment()")
}

func mustContain(t *testing.T, files map[string]string, path, substr string) {
	t.Helper()
	content, ok := files[path]
	if !ok {
		t.Errorf("missing generated file %s", path)
		return
	}
	if !strings.Contains(content, substr) {
		t.Errorf("expected %s to contain %q, got:\n%s", path, substr, content)
	}
}
