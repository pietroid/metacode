// Package behaviorflutter generates the Flutter code that behaviors imply: the
// tests that verify each scenario, the wrappers that wire widgets to stores,
// and the implement stage that fills in what no spec can derive.
//
// Everything before the implement stage is deterministic: the specs decide
// which stores, widgets, wrappers and tests exist, what they are called, and
// where they live. What is left is the body of a store action and the wiring of
// a widget, and that is what a model is asked for — once, with the whole spec,
// every test, and every file it may write. See AGENTS.md, "Ask once, with
// everything".
package behaviorflutter

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
	"github.com/pietroid/metacode/engine/internal/core/run"
	"github.com/pietroid/metacode/engine/internal/llm"
	"github.com/pietroid/metacode/engine/internal/log"
)

// Implementer turns a scaffolded project into a working one.
type Implementer struct {
	Client     llm.Client
	Logger     log.Logger
	ProjectDir string
	App        *model.App
	Work       plan.Work
}

// New returns an Implementer writing into projectDir.
func New(client llm.Client, logger log.Logger, app *model.App, work plan.Work, projectDir string) *Implementer {
	if logger == nil {
		logger = log.Nop()
	}
	return &Implementer{
		Client:     client,
		Logger:     logger,
		ProjectDir: projectDir,
		App:        app,
		Work:       work,
	}
}

// editableFile is a file the model may rewrite, together with the class it has
// to declare. The class is checked rather than trusted: a model is free to
// rename what it is handed, and app.dart and the tests are not.
type editableFile struct {
	Path  string // relative to the project root
	Class string // empty when no particular class name is required
	Role  string // "store" or "wrapper", for the prompt
}

// editableFiles is the complete set of files this stage owns. Nothing outside
// it is written, whatever the reply contains: the dumb widgets, the state
// classes and the tests are derived from the specs, and a model that rewrites
// a test to match its code has verified nothing.
func (im *Implementer) editableFiles() []editableFile {
	var files []editableFile

	for _, store := range im.App.Stores {
		files = append(files, editableFile{
			Path:  dart.CubitFile(store.Name),
			Class: dart.CubitClass(store.Name),
			Role:  "store",
		})
	}

	for _, widget := range im.Work.Wrappers {
		files = append(files, editableFile{
			Path:  dart.WrapperFile(widget),
			Class: dart.WrapperClass(widget),
			Role:  "wrapper",
		})
	}

	return files
}

// Implement makes the one request that writes the behavior of the whole app.
func (im *Implementer) Implement(ctx context.Context) error {
	if im.Client == nil {
		return fmt.Errorf("no LLM client configured")
	}

	files := im.editableFiles()
	if len(files) == 0 {
		im.Logger.Infof("nothing to implement: no stores and no wrappers")
		return nil
	}

	prefix, err := im.buildPrefix()
	if err != nil {
		return fmt.Errorf("build prompt: %w", err)
	}
	suffix, err := im.buildImplementSuffix(files)
	if err != nil {
		return fmt.Errorf("build prompt: %w", err)
	}

	im.Logger.Infof("implementing %d file(s) in one request: %s", len(files), strings.Join(paths(files), ", "))

	result, err := im.Client.Complete(ctx, llm.Call{Label: "implement", Prefix: prefix, Prompt: suffix})
	if err != nil {
		return fmt.Errorf("LLM complete: %w", err)
	}

	written, err := im.apply(result.Text, files)
	if err != nil {
		return err
	}
	if written == 0 {
		return fmt.Errorf("the model returned no usable file for any of: %s", strings.Join(paths(files), ", "))
	}
	return nil
}

// Repair makes one request per fix iteration, carrying every failure at once:
// the failures of a run are usually the same mistake seen from several
// scenarios. See AGENTS.md, "Ask once, with everything".
func (im *Implementer) Repair(ctx context.Context, iteration int, failures []run.Failure) error {
	if im.Client == nil {
		return fmt.Errorf("no LLM client configured")
	}
	if len(failures) == 0 {
		return nil
	}

	files := im.editableFiles()
	prefix, err := im.buildPrefix()
	if err != nil {
		return fmt.Errorf("build prompt: %w", err)
	}
	suffix, err := im.buildRepairSuffix(files, failures)
	if err != nil {
		return fmt.Errorf("build prompt: %w", err)
	}

	im.Logger.Infof("repairing %d failure(s) in one request", len(failures))

	label := fmt.Sprintf("repair %d", iteration)
	result, err := im.Client.Complete(ctx, llm.Call{Label: label, Prefix: prefix, Prompt: suffix})
	if err != nil {
		return fmt.Errorf("LLM complete: %w", err)
	}

	if _, err := im.apply(result.Text, files); err != nil {
		return err
	}
	return nil
}

// apply writes back the files the reply carries. Files it does not mention are
// left alone, which is how a repair that only touches the store leaves a
// working wrapper untouched.
func (im *Implementer) apply(raw string, files []editableFile) (int, error) {
	blocks, err := ParseFileBlocks(raw)
	if err != nil {
		return 0, err
	}

	allowed := make(map[string]editableFile, len(files))
	for _, f := range files {
		allowed[f.Path] = f
	}

	written := 0
	var discarded []string
	for _, block := range blocks {
		file, ok := allowed[block.Path]
		if !ok {
			im.Logger.Warnf("ignored %s: not a file this stage owns", block.Path)
			continue
		}
		if err := dart.Validate(block.Code); err != nil {
			// Loudly. A discard means the model did the work and the engine
			// threw it away: a run once repeated that three times over a
			// bracket check that could not read comments, and reported the
			// untouched scaffolding as the result.
			im.Logger.Errorf("DISCARDED %s: %s", block.Path, err)
			discarded = append(discarded, block.Path)
			continue
		}
		if err := im.writeFile(file, block.Code); err != nil {
			return written, err
		}
		written++
	}

	for _, f := range files {
		if !mentions(blocks, f.Path) {
			im.Logger.Infof("%s left unchanged: the reply did not include it", f.Path)
		}
	}
	if len(discarded) > 0 {
		im.Logger.Errorf("%d file(s) discarded as invalid Dart: %s", len(discarded), strings.Join(discarded, ", "))
	}

	return written, nil
}

// writeFile writes one file the model returned, after making it answer to the
// name the rest of the generated app calls it by.
func (im *Implementer) writeFile(file editableFile, code string) error {
	if file.Class != "" && file.Role == "wrapper" {
		code = dart.RenameClass(code, file.Class)
	}

	full := filepath.Join(im.ProjectDir, file.Path)
	existing, _ := os.ReadFile(full)
	code = preserveMarker(string(existing), code)

	if err := os.MkdirAll(filepath.Dir(full), 0755); err != nil {
		return fmt.Errorf("create dir for %s: %w", file.Path, err)
	}
	if err := os.WriteFile(full, []byte(code), 0644); err != nil {
		return fmt.Errorf("write %s: %w", file.Path, err)
	}
	im.Logger.Infof("wrote %s (%d bytes)", file.Path, len(code))
	return nil
}

// preserveMarker keeps the generated-file header when a reply drops it. Stale
// output is pruned by that marker, so an unmarked file is one nothing can
// clean up later.
func preserveMarker(oldCode, newCode string) string {
	if strings.Contains(newCode, dart.Marker) {
		return newCode
	}
	for _, line := range strings.Split(oldCode, "\n") {
		if strings.Contains(line, dart.Marker) {
			return line + "\n" + newCode
		}
	}
	return "// " + dart.Marker + " - DO NOT EDIT BY HAND\n" + newCode
}

func mentions(blocks []FileBlock, path string) bool {
	for _, b := range blocks {
		if b.Path == path {
			return true
		}
	}
	return false
}

func paths(files []editableFile) []string {
	out := make([]string, 0, len(files))
	for _, f := range files {
		out = append(out, f.Path)
	}
	return out
}
