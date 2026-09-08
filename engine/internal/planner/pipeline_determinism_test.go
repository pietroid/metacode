// This file lives in the external test package (planner_test) because it
// exercises the whole deterministic pipeline: core/ir -> planner -> modules.
// The tests module imports planner, so an internal test would create a cycle.
package planner_test

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	codegenflutter "github.com/pietroid/metacode/engine/internal/modules/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
	"github.com/pietroid/metacode/engine/internal/planner"
)

// runs is high enough that Go's randomized map iteration order will show up if
// any generation step walks a map without sorting its keys.
const runs = 25

// counterSpecs is the counter app from examples/, plus a second store action so
// the store generator has more than one method to emit. A single method cannot
// expose an ordering bug.
func counterSpecs() spec.RawSpecs {
	return spec.RawSpecs{
		Project: map[string]any{
			"name":        "counter_app",
			"description": "Counter app example for Metacode.",
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
						"appBar": map[string]any{"title": "Counter App"},
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
					"elevatedButton": map[string]any{"child": "Increment"},
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
				"decrements from 5": map[string]any{
					"given": "counterStore.value is 5",
					"when":  "counterStore.decrement",
					"then":  "counterStore.value should be 4",
				},
				"Show counter value on the home page": map[string]any{
					"given": "counterStore.value = 5",
					"then":  "homePage.counterValue = 5",
				},
			},
		},
	}
}

// generateOnce runs the full deterministic pipeline into outDir and returns the
// planned task IDs in order.
func generateOnce(t *testing.T, outDir string) []string {
	t.Helper()

	app, err := ir.Build(counterSpecs())
	if err != nil {
		t.Fatalf("build ir: %v", err)
	}
	if err := app.Resolve(catalog.New()); err != nil {
		t.Fatalf("resolve: %v", err)
	}
	if err := codegenflutter.GenerateAll(&app, outDir); err != nil {
		t.Fatalf("generate project: %v", err)
	}

	tasks, err := planner.Plan(&app)
	if err != nil {
		t.Fatalf("plan: %v", err)
	}
	if err := codegenflutter.NewWrapperGenerator().Generate(context.Background(), &app, tasks, outDir); err != nil {
		t.Fatalf("generate wrappers: %v", err)
	}
	if err := codegenflutter.GenerateTests(&app, tasks, outDir); err != nil {
		t.Fatalf("generate tests: %v", err)
	}

	ids := make([]string, 0, len(tasks))
	for _, task := range tasks {
		ids = append(ids, string(task.Type)+":"+task.ID)
	}
	return ids
}

// manifest returns a sorted "path\thash" listing of every file under root, so
// two generated trees can be compared as a single string.
func manifest(t *testing.T, root string) string {
	t.Helper()

	var lines []string
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		sum := sha256.Sum256(content)
		lines = append(lines, fmt.Sprintf("%s\t%s", filepath.ToSlash(rel), hex.EncodeToString(sum[:])))
		return nil
	})
	if err != nil {
		t.Fatalf("walk %s: %v", root, err)
	}

	sort.Strings(lines)
	return strings.Join(lines, "\n")
}

// TestGenerationIsReproducible asserts that generating the same specs twice
// produces byte-identical output. Reproducible output is a precondition for the
// lock/diff optimization described in the README: a diff over generated files is
// meaningless if unchanged specs still produce different bytes.
func TestGenerationIsReproducible(t *testing.T) {
	base := manifest(t, generateInto(t))

	for i := 1; i < runs; i++ {
		got := manifest(t, generateInto(t))
		if got != base {
			t.Fatalf("generation is not reproducible on run %d\n%s", i+1, diffManifests(base, got))
		}
	}
}

// TestPlanIsReproducible isolates the planner from the generators: the ordered
// task list must not depend on map iteration order.
func TestPlanIsReproducible(t *testing.T) {
	base := strings.Join(generateOnce(t, t.TempDir()), "\n")

	for i := 1; i < runs; i++ {
		got := strings.Join(generateOnce(t, t.TempDir()), "\n")
		if got != base {
			t.Fatalf("plan is not reproducible on run %d\nfirst:\n%s\ngot:\n%s", i+1, base, got)
		}
	}
}

func generateInto(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	generateOnce(t, dir)
	return dir
}

// diffManifests reports the entries that differ between two manifests.
func diffManifests(want, got string) string {
	wantLines := map[string]string{}
	for _, line := range strings.Split(want, "\n") {
		path, hash, _ := strings.Cut(line, "\t")
		wantLines[path] = hash
	}

	var b strings.Builder
	for _, line := range strings.Split(got, "\n") {
		path, hash, _ := strings.Cut(line, "\t")
		if wantHash, ok := wantLines[path]; !ok {
			fmt.Fprintf(&b, "  only in second run: %s\n", path)
		} else if wantHash != hash {
			fmt.Fprintf(&b, "  differs: %s\n", path)
		}
		delete(wantLines, path)
	}
	for path := range wantLines {
		fmt.Fprintf(&b, "  only in first run: %s\n", path)
	}
	return b.String()
}
