package behaviorflutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

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

	// One wrapper, for the page. The page's generated widget takes a callback
	// per event of every widget it embeds, so a wrapper per button would be
	// written and referenced by nothing.
	if _, err := os.Stat(filepath.Join(dir, "lib/wrappers/home_page_wrapper.dart")); err != nil {
		t.Errorf("expected the page wrapper to exist: %v", err)
	}
	for _, name := range []string{"lib/wrappers/increment_button_wrapper.dart", "lib/wrappers/decrement_button_wrapper.dart"} {
		if _, err := os.Stat(filepath.Join(dir, name)); err == nil {
			t.Errorf("%s was written, but nothing can reference it", name)
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
