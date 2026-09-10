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

	"github.com/pietroid/metacode/engine/internal/behavior/rules"
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
	Name  string // the store or widget it belongs to, as the specs name it
}

// ownedFiles is the complete set of files this stage may ever write. Nothing
// outside it is written, whatever the reply contains: the dumb widgets, the
// state classes and the tests are derived from the specs, and a model that
// rewrites a test to match its code has verified nothing.
func (im *Implementer) ownedFiles() []editableFile {
	var files []editableFile

	for _, store := range im.App.Stores {
		files = append(files, editableFile{
			Path:  dart.CubitFile(store.Name),
			Class: dart.CubitClass(store.Name),
			Role:  "store",
			Name:  store.Name,
		})
	}

	for _, widget := range im.Work.Wrappers {
		files = append(files, editableFile{
			Path:  dart.WrapperFile(widget),
			Class: dart.WrapperClass(widget),
			Role:  "wrapper",
			Name:  widget,
		})
	}

	return files
}

// editableFiles is the subset of the owned files this run offers to a model.
//
// The rest are frozen. They are still printed, as code to read and not change,
// so the model writes against the whole app rather than the slice that
// changed. Freezing shows up in what the model is asked to produce rather than
// in what it is shown, which is where the cost is: output is the expensive
// half of a request, and a narrower write is a more accurate one.
//
// Frozen files stay in the suffix rather than moving to the read-only section
// of the prefix, because the prefix is byte-identical across a run and a
// repair has to be able to reach a file the implement call could not. A file
// listed as "never change" in a cached prefix and as writable in a repair
// would be two instructions about one file.
//
// Three things unfreeze a file, and they answer different questions. The diff
// says what the author changed. The stub header says the file has never been
// implemented, which is the only signal that survives a deleted lib/ or a
// fresh clone, neither of which a spec diff can see. Signature drift says the
// specs have moved under a preserved file, which happens because the scaffold
// no longer rewrites it.
func (im *Implementer) editableFiles() []editableFile {
	var files []editableFile
	for _, f := range im.ownedFiles() {
		if reason, ok := im.unfrozen(f); ok {
			im.Logger.Debugf("%s is open for rewriting: %s", f.Path, reason)
			files = append(files, f)
			continue
		}
		im.Logger.Debugf("%s is frozen: nothing this run changed reaches it", f.Path)
	}
	return files
}

// unfrozen reports whether a model may write this file, and why.
func (im *Implementer) unfrozen(f editableFile) (string, bool) {
	stale := im.Work.Stale
	switch f.Role {
	case "store":
		if stale.HasStore(f.Name) {
			return "the specs behind it changed", true
		}
	case "wrapper":
		if stale.HasWrapper(f.Name) {
			return "the specs behind it changed", true
		}
	}

	full := filepath.Join(im.ProjectDir, f.Path)
	if !dart.IsImplemented(full) {
		return "it has never been implemented", true
	}
	if missing := im.missingSignatures(f); len(missing) > 0 {
		return "it is missing " + strings.Join(missing, ", "), true
	}
	return "", false
}

// missingSignatures reports the store actions the specs imply that a
// preserved file does not declare.
//
// This is the cost of not re-scaffolding a Cubit: an action added to
// behaviors.yaml no longer arrives as a stub method, because the generator
// that would have written it skipped the file. The answer is not to patch
// Dart, which would put a second code writer in the engine. It is to notice
// and delegate: the file is unfrozen, and the prompt is told which signatures
// it owes.
//
// The check is a name search rather than a parse. A false positive unfreezes a
// file that did not need it, which costs part of one request; a parser here
// would cost a parser here.
func (im *Implementer) missingSignatures(f editableFile) []string {
	if f.Role != "store" {
		return nil
	}
	store, ok := im.storeNamed(f.Name)
	if !ok {
		return nil
	}
	code, err := os.ReadFile(filepath.Join(im.ProjectDir, f.Path))
	if err != nil {
		return nil
	}

	var missing []string
	for _, action := range behaviorrules.StoreActions(im.App, store) {
		if !strings.Contains(string(code), action.Name+"(") {
			missing = append(missing, action.Name)
		}
	}
	return missing
}

func (im *Implementer) storeNamed(name string) (model.Store, bool) {
	for _, store := range im.App.Stores {
		if store.Name == name {
			return store, true
		}
	}
	return model.Store{}, false
}

// Implement makes the one request that writes the behavior of the whole app.
func (im *Implementer) Implement(ctx context.Context) error {
	if im.Client == nil {
		return fmt.Errorf("no LLM client configured")
	}

	// An empty set is the lock paying off: every owned file is already
	// implemented and nothing this run changed reaches it, so the one
	// expensive stage is skipped entirely. The suite still runs, and a failure
	// still enters the repair loop, which opens everything.
	files := im.editableFiles()
	if len(files) == 0 {
		im.Logger.Infof("nothing to implement: every store and wrapper is up to date")
		return nil
	}

	prefix, err := im.buildPrefix()
	if err != nil {
		return fmt.Errorf("build prompt: %w", err)
	}
	suffix, err := im.buildImplementSuffix(im.ownedFiles(), files)
	if err != nil {
		return fmt.Errorf("build prompt: %w", err)
	}

	im.Logger.Infof("implementing %d of %d owned file(s) in one request: %s",
		len(files), len(im.ownedFiles()), strings.Join(paths(files), ", "))

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

	// Every owned file, not just the ones the diff opened. A run reaches here
	// because something the diff called untouched is in fact broken, which is
	// exactly the case the classification is allowed to get wrong: a renamed
	// variable that changes logic looks like a layout edit. The suite is what
	// catches it, and the repair is what fixes it, so the repair sees
	// everything.
	files := im.ownedFiles()
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
	code = preserveMarker(code)

	if err := os.MkdirAll(filepath.Dir(full), 0755); err != nil {
		return fmt.Errorf("create dir for %s: %w", file.Path, err)
	}
	if err := os.WriteFile(full, []byte(code), 0644); err != nil {
		return fmt.Errorf("write %s: %w", file.Path, err)
	}
	im.Logger.Infof("wrote %s (%d bytes)", file.Path, len(code))
	return nil
}

// preserveMarker gives the file the model just wrote the implemented header.
// Stale output is pruned by the marker, so an unmarked file is one nothing can
// clean up later, and a file that kept the stub header would be re-scaffolded
// on the next run and lose exactly the work this stage paid for.
//
// A reply that carried its own marker line has it replaced rather than
// trusted: the model is copying the header it was shown, which is the stub
// one whenever this is the first implement pass over the file.
func preserveMarker(newCode string) string {
	var kept []string
	for _, line := range strings.Split(newCode, "\n") {
		if strings.Contains(line, dart.Marker) {
			continue
		}
		kept = append(kept, line)
	}
	return dart.ImplementedHeader + "\n" + strings.TrimLeft(strings.Join(kept, "\n"), "\n")
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
