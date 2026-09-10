package behaviorflutter

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/plan"
	"github.com/pietroid/metacode/engine/internal/core/run"
	"github.com/pietroid/metacode/engine/internal/log"
)

// implemented rewrites a file as one a model has already written, which is the
// state a second run finds every owned file in.
func implemented(t *testing.T, dir, rel, body string) {
	t.Helper()
	path := filepath.Join(dir, rel)
	if err := os.WriteFile(path, []byte(dart.ImplementedHeader+"\n"+body), 0644); err != nil {
		t.Fatalf("write %s: %v", rel, err)
	}
}

// implementedApp is a project where every owned file has been written, so
// nothing is a stub and the freeze set is decided by the diff alone.
func implementedApp(t *testing.T, stale plan.Stale) (*Implementer, string) {
	t.Helper()
	app, work, dir := scaffold(t)
	work.Stale = stale

	implemented(t, dir, dart.CubitFile("counterStore"),
		"class CounterCubit { void increment() {} void decrement() {} }\n")
	for _, widget := range work.Wrappers {
		implemented(t, dir, dart.WrapperFile(widget),
			"class "+dart.WrapperClass(widget)+" {}\n")
	}
	return New(&recordingClient{}, log.Nop(), app, work, dir), dir
}

// TestNothingStaleMakesNoRequest is the payoff. Every owned file is
// implemented and nothing the author changed reaches it, so the one expensive
// stage of a run does not happen at all.
func TestNothingStaleMakesNoRequest(t *testing.T) {
	impl, _ := implementedApp(t, plan.Stale{})
	client := &recordingClient{}
	impl.Client = client

	if err := impl.Implement(context.Background()); err != nil {
		t.Fatalf("implement: %v", err)
	}
	if len(client.calls) != 0 {
		t.Errorf("expected no LLM call, got %d", len(client.calls))
	}
}

// TestOnlyTheStaleFilesAreAskedFor: the output format is the contract, and a
// path missing from it is a file the reply cannot write.
func TestOnlyTheStaleFilesAreAskedFor(t *testing.T) {
	impl, _ := implementedApp(t, plan.Stale{Wrappers: []string{"incrementButton"}})
	client := &recordingClient{responses: []string{""}}
	impl.Client = client

	if err := impl.Implement(context.Background()); err == nil {
		t.Fatal("an empty reply should be reported, not accepted")
	}
	prompt := client.calls[0].Text()

	wanted := dart.WrapperFile("incrementButton")
	frozen := dart.CubitFile("counterStore")
	if !strings.Contains(prompt, "YOURS TO WRITE. role: wrapper") {
		t.Error("the stale wrapper was not offered")
	}
	if !strings.Contains(prompt, "ALREADY CORRECT, do not return it. role: store") {
		t.Error("the frozen store was not marked as frozen")
	}
	if !strings.Contains(prompt, frozen) {
		t.Error("a frozen file must still be shown: the wrapper calls into it")
	}

	format := prompt[strings.Index(prompt, "You may write only these paths:"):]
	if !strings.Contains(format, wanted) {
		t.Errorf("the stale wrapper is not in the allowed paths:\n%s", format)
	}
	if strings.Contains(format, frozen) {
		t.Errorf("a frozen file was left writable:\n%s", format)
	}
}

// TestAStubIsAlwaysStale is the signal the lock cannot give. A deleted
// lib/stores or a fresh clone leaves the specs matching the lock exactly and
// the code missing entirely, and only the file's own header says so.
func TestAStubIsAlwaysStale(t *testing.T) {
	impl, dir := implementedApp(t, plan.Stale{})
	path := filepath.Join(dir, dart.CubitFile("counterStore"))
	if err := os.WriteFile(path, []byte(dart.StubHeader+"\nclass CounterCubit {}\n"), 0644); err != nil {
		t.Fatalf("write: %v", err)
	}

	var found bool
	for _, f := range impl.editableFiles() {
		found = found || f.Path == dart.CubitFile("counterStore")
	}
	if !found {
		t.Error("a file no model has written was frozen")
	}
}

// TestADriftedSignatureIsStale is the cost of preserving Cubits: an action the
// specs added since never arrived as a stub method, because the generator that
// would have written it skipped the file.
func TestADriftedSignatureIsStale(t *testing.T) {
	impl, dir := implementedApp(t, plan.Stale{})
	implemented(t, dir, dart.CubitFile("counterStore"),
		"class CounterCubit { void increment() {} }\n")

	files := impl.editableFiles()
	if len(files) != 1 || files[0].Path != dart.CubitFile("counterStore") {
		t.Fatalf("expected only the drifted Cubit to be stale, got %v", paths(files))
	}

	client := &recordingClient{responses: []string{""}}
	impl.Client = client
	_ = impl.Implement(context.Background())
	if !strings.Contains(client.calls[0].Text(), "add the missing action(s): decrement") {
		t.Error("the model was not told which signature it owes")
	}
}

// TestRepairOpensEverything is the safety net the whole classification rests
// on. A run reaches a repair because something the diff called untouched is
// broken, which is exactly the case it is allowed to get wrong.
func TestRepairOpensEverything(t *testing.T) {
	impl, _ := implementedApp(t, plan.Stale{Wrappers: []string{"incrementButton"}})
	client := &recordingClient{responses: []string{""}}
	impl.Client = client

	// The reply is empty, so applying it fails. What this test reads is the
	// request that was sent, which is built before any reply arrives.
	_ = impl.Repair(context.Background(), 1, []run.Failure{{File: "test/a_test.dart", Name: "increments"}})
	if len(client.calls) != 1 {
		t.Fatalf("expected one repair request, got %d", len(client.calls))
	}

	format := client.calls[0].Text()
	format = format[strings.Index(format, "You may write only these paths:"):]
	for _, want := range []string{dart.CubitFile("counterStore"), dart.WrapperFile("incrementButton")} {
		if !strings.Contains(format, want) {
			t.Errorf("a repair could not reach %s", want)
		}
	}
}
