package behaviorflutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
	"github.com/pietroid/metacode/engine/internal/specs/data/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/specs/project/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
	"github.com/pietroid/metacode/engine/internal/specs/ui/codegen/flutter"
)

func setupGeneratedFiles(t *testing.T, app *model.App) string {
	t.Helper()
	dir := t.TempDir()

	if err := projectflutter.Generate(app, dir); err != nil {
		t.Fatalf("project generation: %v", err)
	}
	if err := dataflutter.Generate(app, dir); err != nil {
		t.Fatalf("store generation: %v", err)
	}
	if err := uiflutter.Generate(app, catalog.Default(), dir); err != nil {
		t.Fatalf("widget generation: %v", err)
	}
	return dir
}

func TestGenerateWrappersWritesFiles(t *testing.T) {
	app := counterApp()
	dir := setupGeneratedFiles(t, app)

	work, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	if err := GenerateWrappers(app, work, dir); err != nil {
		t.Fatalf("generate wrappers failed: %v", err)
	}

	// One wrapper per widget with something to wire, and the page takes each of
	// them as a slot.
	for _, name := range []string{
		"lib/wrappers/home_page_wrapper.dart",
		"lib/wrappers/increment_button_wrapper.dart",
	} {
		if _, err := os.Stat(filepath.Join(dir, name)); err != nil {
			t.Errorf("expected %s to exist: %v", name, err)
		}
	}

	page, err := os.ReadFile(filepath.Join(dir, "lib/wrappers/home_page_wrapper.dart"))
	if err != nil {
		t.Fatalf("read the page wrapper: %v", err)
	}
	for _, want := range []string{
		"incrementButton: const IncrementButtonWrapper()",
		"import '../wrappers/increment_button_wrapper.dart';",
	} {
		if !strings.Contains(string(page), want) {
			t.Errorf("expected the page wrapper to contain %q, got:\n%s", want, string(page))
		}
	}

	button, err := os.ReadFile(filepath.Join(dir, "lib/wrappers/increment_button_wrapper.dart"))
	if err != nil {
		t.Fatalf("read the button wrapper: %v", err)
	}
	if !strings.Contains(string(button), "onPressed: () => context.read<CounterCubit>().increment()") {
		t.Errorf("expected the button wrapper to wire its own event, got:\n%s", string(button))
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

func TestReplacePageWithWrapperHandlesNestedCalls(t *testing.T) {
	src := "home: const HomePage(homeContent: SizedBox()),"
	got := replacePageWithWrapper(src, "HomePage", "HomePageWrapper")
	want := "home: const HomePageWrapper(),"
	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
	if !dart.Balanced(got) {
		t.Error("replacement left unbalanced brackets")
	}
}

func TestReplacePageWithWrapperLeavesOtherWidgetsAlone(t *testing.T) {
	src := "home: const HomePageHeader(title: 'x'),"
	if got := replacePageWithWrapper(src, "HomePage", "HomePageWrapper"); got != src {
		t.Errorf("rewrote an unrelated widget: %q", got)
	}
}

// TestWrappersNest is the shape this layer exists to hold: one wrapper per
// widget with something to wire, each filling its own widget's parameters and
// handing the slot below it to the wrapper that owns it. A row wrapper is told
// which row it is and passes that down, so every widget in a row keys itself by
// the same index.
func TestWrappersNest(t *testing.T) {
	app := listApp(t)
	dir := setupGeneratedFiles(t, app)

	work, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}
	if err := GenerateWrappers(app, work, dir); err != nil {
		t.Fatalf("generate wrappers failed: %v", err)
	}

	for file, wants := range map[string][]string{
		"lib/wrappers/home_page_wrapper.dart": {
			"homeContent: const DefaultStateWrapper()",
		},
		"lib/wrappers/default_state_wrapper.dart": {
			"taskTile: (context, index) => TaskTileWrapper(index: index)",
		},
		"lib/wrappers/task_tile_wrapper.dart": {
			"const TaskTileWrapper({super.key, required this.index});",
			"final int index;",
			"index: index",
			"taskCheckbox: TaskCheckboxWrapper(index: index)",
		},
		"lib/wrappers/task_checkbox_wrapper.dart": {
			"taskToggled: (_) => context.read<TaskCubit>().",
		},
	} {
		content, err := os.ReadFile(filepath.Join(dir, file))
		if err != nil {
			t.Errorf("read %s: %v", file, err)
			continue
		}
		for _, want := range wants {
			if !strings.Contains(string(content), want) {
				t.Errorf("expected %s to contain %q, got:\n%s", file, want, string(content))
			}
		}
	}

	// The row wrapper wires its own widget and nothing under it: what the
	// checkbox shows is the checkbox wrapper's business.
	tile, err := os.ReadFile(filepath.Join(dir, "lib/wrappers/task_tile_wrapper.dart"))
	if err != nil {
		t.Fatalf("read the row wrapper: %v", err)
	}
	for _, unwanted := range []string{"taskDone", "TaskCheckbox("} {
		if strings.Contains(string(tile), unwanted) {
			t.Errorf("expected the row wrapper not to reach into its child, found %q in:\n%s", unwanted, string(tile))
		}
	}
}
