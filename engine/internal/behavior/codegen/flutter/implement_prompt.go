package behaviorflutter

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/run"
)

const rules = `Rules:
- The dumb widgets, the state classes and the tests are generated from the specs. Never rewrite them.
- Business rules live in the Cubit. A widget calls Cubit methods; a widget never calls emit.
- A wrapper instantiates its own dumb widget and passes its constructor parameters, and that is all it
  is: one constructor call. Do not reimplement the widget, do not wrap it in a GestureDetector or
  InkWell, and declare exactly one class per file.
- A parameter holding a widget is a slot the scaffolding has already filled with the child's own
  wrapper. Keep it as it is. Never construct another widget's children inside a wrapper: the widget
  tree comes from the specs, and each wired widget has a wrapper of its own that fills it.
- Pass every callback parameter a dumb widget declares. A parameter left out is a dead control.
- Use flutter_bloc. Read Cubits with context.read, rebuild with BlocSelector or BlocBuilder.
- Inside lib, use relative imports (../widgets/, ../pages/, ../stores/), never package: imports of this project.
- Keep every declaration a file already has, including the seeded constructor and methods no test exercises.
- Implement the behavior described by the scenarios, not only the literal values the tests check.
  "not decrements when is 0" is a rule about every value at the floor, not about the number 0.
`

// buildPrefix assembles the part of a request that is byte-identical across
// every call of one run: the standing instructions, the spec, the tests, and
// the generated code the model reads but never writes. Nothing in it is
// rewritten between the implement call and the repairs that follow, so it is
// sent once and re-read.
//
// The task itself is deliberately not here. "Implement this" and "fix these
// failures" are one word apart in cost and would split the prefix in two, so
// they go in the suffix and this stays one cache entry per run. See AGENTS.md,
// "One prefix per run".
func (im *Implementer) buildPrefix() (string, error) {
	var b strings.Builder

	b.WriteString("You are writing the behavior of a Flutter app that has already been scaffolded from a\n")
	b.WriteString("specification. The scaffolding is complete and correct: the classes, their names, and the\n")
	b.WriteString("files they live in all come from the spec. What is missing is behavior — the bodies of the\n")
	b.WriteString("store actions and the wiring between widgets and stores.\n\n")
	b.WriteString(rules)
	b.WriteString("\n")

	if err := im.writeContext(&b); err != nil {
		return "", err
	}
	return b.String(), nil
}

// buildImplementSuffix is the half of the implement request that the repairs
// do not share: the files as they stand, and the instruction.
func (im *Implementer) buildImplementSuffix(files []editableFile) (string, error) {
	var b strings.Builder

	if err := im.writeEditable(&b, files); err != nil {
		return "", err
	}
	writeOutputFormat(&b, files)
	b.WriteString("Write the behavior of the whole app.\n")
	return b.String(), nil
}

// buildRepairSuffix carries every failure of one test run.
func (im *Implementer) buildRepairSuffix(files []editableFile, failures []run.Failure) (string, error) {
	var b strings.Builder

	if err := im.writeEditable(&b, files); err != nil {
		return "", err
	}

	b.WriteString("=== Failing tests ===\n")
	for _, f := range failures {
		fmt.Fprintf(&b, "\n--- %s: %s ---\n", f.File, f.Name)
		if f.Message != "" {
			b.WriteString(f.Message)
			b.WriteString("\n")
		}
	}
	b.WriteString("\n")

	writeOutputFormat(&b, files)
	b.WriteString("The tests are generated from the specification and are correct by definition: make the app\n")
	b.WriteString("satisfy them. Fix the cause, not the assertion.\n")
	b.WriteString("Return only the files you are changing. Files you leave out keep their current contents.\n")
	return b.String(), nil
}

// writeContext writes everything both requests need: the spec, the generated
// code the model must read but not change, and every test.
func (im *Implementer) writeContext(b *strings.Builder) error {
	app := im.App

	if err := im.writeScenarios(b); err != nil {
		return err
	}

	b.WriteString("=== Specification: stores ===\n")
	for _, store := range app.Stores {
		fmt.Fprintf(b, "%s: value type %s, initial %v, strategy %s\n", store.Name, store.ValueType, store.InitialValue, store.Strategy)
	}
	b.WriteString("\n")

	if len(app.Symbols.Bindings) > 0 {
		b.WriteString("=== Widget events and the store actions they run ===\n")
		b.WriteString("These are resolved from the spec. Wire exactly these.\n")
		for _, binding := range app.Symbols.Bindings {
			fmt.Fprintf(b, "%s -> %s.%s\n", binding.FullPath(), binding.Store, binding.Action)
		}
		b.WriteString("\n")
	}

	b.WriteString("=== Generated code you must read but never change ===\n")
	for _, path := range im.readOnlyFiles() {
		if err := appendFile(b, im.ProjectDir, path); err != nil {
			return err
		}
	}
	b.WriteString("\n")

	return nil
}

// writeScenarios writes the specification and the suite in one section,
// because they are one thing said twice: every scenario becomes exactly one
// test, and printing the scenario and then the whole generated file repeated
// the given, the when and the then in two notations.
//
// What the file adds over the scenario is the Dart the engine chose, and only
// that is printed. It is not derivable by reading the scenario: two `then`
// lines that look alike compile to different idioms, one searching rendered
// text and the other reading a property off a widget, and a row selector
// became an index by counting the given. A model left to guess at the
// assertion it has to satisfy guesses wrong some of the time, and every wrong
// guess costs a repair.
//
// The cases come from BuildTestCases, the same function that renders the
// files, so this cannot drift from what is on disk.
func (im *Implementer) writeScenarios(b *strings.Builder) error {
	cases, err := BuildTestCases(im.App, im.Work)
	if err != nil {
		return fmt.Errorf("build test cases: %w", err)
	}

	b.WriteString("=== The scenarios, and the test each one compiles to ===\n")
	b.WriteString("These are the specification and the definition of done. Every test must pass.\n")
	b.WriteString("Implement what the scenario describes, not only the value its test checks.\n\n")
	writeTestSkeleton(b, cases)

	byID := make(map[string]TestCase, len(cases))
	for _, tc := range cases {
		byID[tc.ID] = tc
	}
	for _, s := range im.App.Behaviors {
		writeScenario(b, s)
		if tc, ok := byID[s.ID]; ok {
			writeTestHoles(b, tc)
		}
		b.WriteString("\n")
	}
	b.WriteString("\n")
	return nil
}

// writeTestSkeleton prints the shape every test shares, once. Every file is
// this with four holes filled, so printing it eleven times said the same six
// imports and the same pumpWidget call eleven times.
//
// The single pump is part of the contract and is why the skeleton is here at
// all: the app has one frame to settle, and a model that has never seen the
// file cannot know that.
func writeTestSkeleton(b *strings.Builder, cases []TestCase) {
	if len(cases) == 0 {
		return
	}
	tc := cases[0]
	fmt.Fprintf(b, `Each test is one file under test/, and they share one shape:

  void main() {
    testWidgets(<description>, (tester) async {
      final cubit = <cubit>;
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(home: %s()),
        ),
      );
      <action>          // absent when the scenario has no action
      await tester.pump();
      <assert>
    });
  }

Only the four holes differ, and they are listed per scenario below. Note the
single pump: the app has one frame to settle.

`, tc.PageWrapperClass)
}

// writeTestHoles prints what one scenario's test fills the skeleton with.
func writeTestHoles(b *strings.Builder, tc TestCase) {
	fmt.Fprintf(b, "  -> %s\n", tc.TargetFile)
	cubit := tc.CubitClass + "()"
	if tc.SeedState != "" {
		cubit = fmt.Sprintf("%s.seeded(%s)", tc.CubitClass, tc.SeedState)
	}
	fmt.Fprintf(b, "    cubit  %s\n", cubit)
	if tc.ActionExpression != "" {
		fmt.Fprintf(b, "    action %s\n", tc.ActionExpression)
	}
	fmt.Fprintf(b, "    assert %s\n", tc.AssertionExpression)
}

// writeEditable writes the current contents of every file the model owns.
func (im *Implementer) writeEditable(b *strings.Builder, files []editableFile) error {
	b.WriteString("=== The files you are writing, as they stand now ===\n")
	for _, f := range files {
		fmt.Fprintf(b, "\n// role: %s", f.Role)
		if f.Class != "" {
			fmt.Fprintf(b, ", must declare class %s", f.Class)
		}
		b.WriteString("\n")
		if err := appendFile(b, im.ProjectDir, f.Path); err != nil {
			return err
		}
	}
	b.WriteString("\n")
	return nil
}

func writeOutputFormat(b *strings.Builder, files []editableFile) {
	b.WriteString("=== Output format ===\n")
	b.WriteString("Return one ```dart fence per file. The first line inside each fence must be a FILE header:\n\n")
	b.WriteString("```dart\n// FILE: lib/stores/example_cubit.dart\n<the whole file>\n```\n\n")
	b.WriteString("Return whole files, never fragments or diffs. You may write only these paths:\n")
	for _, f := range files {
		fmt.Fprintf(b, "  %s\n", f.Path)
	}
	b.WriteString("Any other path is discarded. Write no prose outside the fences.\n")
}

// readOnlyFiles is the generated code the model needs in order to write against
// it: state classes, the dumb widgets and pages, and the app entry point.
func (im *Implementer) readOnlyFiles() []string {
	var out []string

	for _, store := range im.App.Stores {
		out = append(out, dart.StateFile(store.Name))
	}

	for _, comp := range im.App.UI {
		out = append(out, dart.WidgetFile(comp.Name))
	}

	out = append(out, "lib/app.dart")

	sort.Strings(out)
	return out
}

// writeScenario prints one scenario in the words the spec used. The ID
// already carries the group path and the description, so neither is repeated.
func writeScenario(b *strings.Builder, s model.BehaviorScenario) {
	fmt.Fprintf(b, "%s\n", s.ID)
	if s.Given != nil {
		fmt.Fprintf(b, "    given  %s: %s\n", s.Given.Target, s.Given.Value)
	}
	if s.When != "" {
		fmt.Fprintf(b, "    when   %s\n", s.When)
	}
	if s.Then != nil {
		fmt.Fprintf(b, "    then   %s should be %s\n", s.Then.Target, s.Then.Value)
	}
}

// appendFile writes a file into the prompt under its own path. A file that is
// not there yet is announced rather than skipped, so the model is told the
// difference between "empty" and "absent".
func appendFile(b *strings.Builder, projectDir, rel string) error {
	full := filepath.Join(projectDir, rel)
	code, err := os.ReadFile(full)
	if os.IsNotExist(err) {
		fmt.Fprintf(b, "// %s (does not exist yet)\n\n", rel)
		return nil
	}
	if err != nil {
		return fmt.Errorf("read %s: %w", rel, err)
	}
	fmt.Fprintf(b, "// %s\n%s\n", rel, strings.TrimRight(string(code), "\n"))
	return nil
}
