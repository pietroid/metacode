# Decisions

Why the engine works the way it does. Each entry is a rule that cost something
to learn, kept here so the code can state the rule in a line and point at the
story rather than retelling it in a doc comment.

Dates are when the decision was recorded, not when the code changed.

---

## 2026-09-09 — An event is addressed by the name the widget gives it

A behavior reaches an event three ways, and no others. By an alias, written
where the prop is: `onChanged: taskToggled` makes `taskCheckbox.taskToggled`
that checkbox's onChanged. By a callback prop of the widget's own root, which
needs no alias because a widget has one root: `incrementButton.onPressed`. By
naming the catalog widget on the way, while that names exactly one widget:
`controls.elevatedButton.onPressed`. An alias shadows the prop it names, so
`addTaskButton.onPressed` is an error once that prop is called `onAddTask`. Two
names for one event is how a spec starts disagreeing with itself.

Nothing checked any of this before. The event was whatever text followed the
last dot, so `addTaskButton.onWiggle` resolved, generated a parameter no widget
rendered, left the button at `onPressed: null`, and produced a wrapper that
wired the dead parameter. It compiled, the button did nothing, and the only
symptom was a behavior test failing on a value, which then fed the repair loop a
spec error dressed as a code bug. The middle of a path was discarded rather than
read, so `addTaskButton.banana.onPressed` resolved the same way. Worst of the
three, a custom widget holding two buttons took the event on its root: a Row has
no onPressed, so the parameter attached to nothing and both buttons stayed
disabled.

Resolution stores both, because they answer different questions. The prop says
what the widget does when it fires, so the test picks `tap` from `onChanged`
rather than from a name a spec author chose. The address says which parameter to
fill and which action to run, so two buttons in one row are two bindings and two
store actions rather than one binding that both of them share.

An address also has to be tappable. A named event on an inner widget keys that
widget with its name, so `counterControls.onIncrement` taps the Increment
button. Without it a test taps the middle of the Row and hits neither.

Code: `specs/ui/rules/events.go`, `core/build/resolve.go`, `behavior/rules/binding.go`.

## 2026-09-09 — A widget that needs wiring is reached through its own wrapper

A widget with a variable of its own, or with an event a behavior binds, gets a
wrapper. Its parent declares a `Widget` parameter named after it and renders it
as given, and the parent's wrapper fills that slot with the child's wrapper. The
wrappers nest the way the widgets do, and each one is a single constructor call
that wires its own widget and nothing below it.

One wrapper per page was the rule before, and everything under the page was
forwarded up to it: a page took a callback per event of every widget in its
subtree, and a row widget took the variables of every widget it embedded. The
page wrapper was then the only place any of it could be filled in, which made it
the one file where the model chose the shape of the whole tree. It reimplemented
the item builder, decided what a row was made of, and wired three callbacks to
one action, on a screen whose structure the specs had already settled. The first
level of the tree was deterministic and everything under it was not.

A variable that fills a prop is that prop's callback, so `onChanged: taskToggled`
no longer also generates an unreachable `onChanged` parameter beside it. That is
why a variable now carries the prop it fills.

Code: `specs/ui/rules/wrappers.go`, `specs/ui/codegen/flutter/widget.go`,
`behavior/codegen/flutter/wrappers_render.go`, `core/plan/build.go`.

## 2026-09-09 — A store holds what models.yaml says it holds

models.yaml is read, its shapes generate Dart classes, and a store declaring
`list(task)` gets `List<Task>`. A declared type that is not a primitive is a
class, and a name nothing declares is an error in the model rules rather than a
`dynamic` further down.

The state used to be `List<dynamic>` and a seeded element a map, so a scenario
saying `taskStore.value.first.done` compiled to `['done']` and would have
answered null for a typo. Nothing about the app was checked: `dynamic` accepts
everything, which is the same as checking nothing.

A given is checked against the shape too. Seeding a field the model does not
declare, or leaving out one it requires, names the scenario instead of failing
later as a Dart compile error in a file nobody wrote.

Code: `specs/model/rules`, `specs/model/codegen/flutter`, `codegen/dart/layout.go`.

## 2026-09-09 — A rewrite of generated code is checked like model output is

`app.dart` is edited as text after the wrappers exist, and the result is
bracket-checked before it is written. An unbalanced result is an error and the
file is left as it was.

Model output has been shape-checked since the beginning, on the reasoning that
text which is supposed to be Dart might not be. The engine's own text editing
was trusted instead, and it shipped `const HomePageWrapper())` to disk with an
extra paren, then wrapped that in a BlocProvider, producing a file no reader
could make sense of and no compiler could parse. The immediate cause was
matching a constructor call with `\([^)]*\)`, which stops at the first close
paren and so broke the moment a page took an argument that was itself a call.

Text surgery on generated code is worth removing rather than hardening: app.dart
is written before the wrapper it should point at is planned, which is the only
reason it is patched afterwards at all.

Code: `behavior/codegen/flutter/appdart.go`.

## 2026-09-09 — A row knows which row it is

A widget a list builds one of per element, and every widget that widget embeds,
takes an index and keys itself `taskTile_$index`. A scenario reaches one of them
by `.first` or `.last`.

They used to key themselves by name alone, so N rows carried one key. That is a
duplicate key at runtime and an ambiguous finder in a test, and it left the
whole per-item half of a list spec unable to say anything: `taskTile.taskTitle`
could only mean "some row somewhere shows this".

`last` is knowable because the given says what the list holds, so its length is
the number of rows on screen. A `last` with no list in the given is an error
rather than a guess.

Code: `specs/ui/codegen/flutter/widget.go`, `behavior/codegen/flutter/testcase_build.go`.

## 2026-09-09 — How a value is read back comes from the prop that shows it

A `then` naming a widget variable is compiled by looking up which prop renders
it. A widget prop is rendered as text, so the test looks for text. Any other
prop is read off the built widget, so `taskCheckbox.last.taskDone` becomes
`tester.widget<Checkbox>(...).value`.

Every widget assertion used to be `find.text`, which is right for a title and
meaningless for a checkbox: nothing on screen says "true". The catalog already
knew the prop and its type, and the test builder was not asking.

Counting rows is the one assertion that finds by type rather than by key, for
the reason keys exist: each row has a different one.

Code: `behavior/codegen/flutter/testcase_build.go`.

## 2026-09-09 — A variable can hold a widget, and the behaviors are what say so

A `then` whose value names a widget marks its target as a widget variable. The
generated page takes it as `final Widget`, renders it as itself, and the test
asserts it by key.

`body: homeContent` used to generate `final String homeContent` and
`Text(homeContent)`, because the UI spec cannot tell a widget name from a value
and every variable was assumed to be a string. The page then rendered the word
"defaultState" and the test looked for that text, so a spec about swapping an
empty state for a list compiled into a spec about printing a name.

Code: `core/build/resolve.go`, `specs/ui/codegen/flutter/widget.go`.

## 2026-09-09 — A variable's type comes from the prop it fills

Every catalog prop declares what it holds, in Metacode's own words: text,
boolean, number, list, widget, or a callback carrying one of those. A variable
takes the type of the prop it appears under, and the target maps that to its own
declaration.

Every UI variable used to be generated as `final String`, so a checkbox came out
as `Checkbox(value: taskDone)` with `final String taskDone`, and an `onChanged`
handler was declared as a String and passed where a callback was expected. None
of it compiled, and nothing in the engine had any reason to notice: the type was
never asked, it was assumed.

The one place a type is not read off a prop is a variable holding a widget,
which no prop can express: a behavior comparing it to a widget is what says so,
and resolution writes that back onto the component.

Code: `specs/ui/catalog/definitions.go`, `specs/ui/rules/rules.go`, `codegen/dart/layout.go`.

## 2026-09-09 — A widget takes what the widgets it embeds need

A widget's parameters include the variables of every widget it instantiates, and
it passes them down under the same name. This now covers only the widgets it
still instantiates: one with something to wire arrives as a slot instead, and
brings nothing up with it. See "A widget that needs wiring is reached through its
own wrapper".

`taskTile` embeds `taskCheckbox`, which needs a value and a handler, and the
generated tile called `const TaskCheckbox()` with neither. The parameters existed
on the child and nothing could ever reach them, because only events were
forwarded. The name is not prefixed: in the specs one name means one thing, so
`taskDone` on the tile is the `taskDone` the checkbox shows.

Code: `specs/ui/codegen/flutter/widget.go`.

## 2026-09-09 — Two scenarios cannot write one test file

Test file names are slugs of scenario IDs, and two IDs that slug to the same
name are an error naming both.

The second file would have overwritten the first, so a scenario would stop being
checked while the suite stayed green. Nothing else in the pipeline can drop a
scenario: the planner emits one test per scenario, and the builder errors on
anything it cannot turn into one. This was the only remaining way for a spec to
be quietly untested.

Code: `behavior/codegen/flutter/testcase_build.go`.

## 2026-09-09 — A catalog widget under a widget's mapping is its content

`expanded: {listView: ...}` builds the listView as the child of the Expanded. A
key that names a catalog widget and is not a prop of the enclosing widget is
content, not a prop named after itself.

The UI spec has always documented the nested mapping form, and it only appeared
to work: `body: {center: {column: ...}}` rendered correctly because a prop value
is rendered from its raw map and never becomes a component, so nothing ever
validated it. The moment the same shape appeared inside a children list it did
become a component, and `expanded` came out carrying a prop called `listView`
that the catalog rejected by name.

Code: `specs/ui/rules/rules.go`.

## 2026-09-09 — The catalog names a widget; the target picks the constructor

A `listView` with `items` renders as `ListView.builder`, with `itemCount` from
the collection's length and `itemBuilder` from the widget the spec's `item`
names. The catalog entry still says `ListView`, and the spec still says `items`
and `item`.

The renderer used to pass every catalog prop through as a Flutter named
argument, which works only while the two vocabularies happen to agree. They
stopped agreeing at the first list: `ListView(items: taskList, item:
const TaskTile())` is not a constructor Flutter has. Which constructor to call,
and what to compute for its arguments, is a fact about the target, so it lives
in the target's renderer rather than in the spec or the catalog.

A variable named by `items` is also typed as a list, because a String answers
`.length` too and would have counted characters without complaining.

The builder itself is a parameter, not a closure the generator writes: what a
row shows is a fact about the elements, and no spec joins `taskTitle` to
`task.description`. The wrapper knows, so it passes the builder in the same way
it passes every other value that reaches a store. The row widget is therefore
named by the list and imported by the wrapper, not by the widget that holds the
list.

Code: `specs/ui/codegen/flutter/widget.go`.

## 2026-09-09 — An icon comes from a catalog, and is qualified by it

Icons are a vocabulary beside the widget catalog: an entry maps the name the
spec writes to what the target generates. A value names it as `icons.add`, and
an unqualified or unknown name is an error.

The first attempt made a bare name under `icon` mean the icon, and built the
Flutter constant by prefixing the string. Both halves were wrong. The special
case broke the one rule the spec has about bare names, that they are variables
to bind later, so `icon: currentIcon` could never be dynamic. And string
prefixing pinned the spec to Material's spelling, which is the coupling the
catalog exists to remove: the name is Metacode's, the mapping is the target's,
and `icons.hidden` stays `icons.hidden` when another target calls it something
else.

Code: `specs/ui/catalog/icons.go`, `specs/ui/rules/rules.go`.

## 2026-09-09 — A ui.yaml with no widgets: key is an error

Widgets are declared under one `widgets:` key. A file with content but no such
key is rejected.

It used to build zero widgets and say nothing, so the run failed several stages
later complaining about a widget a behavior referenced, and the message pointed
at the behavior rather than at the missing line.

Code: `specs/ui/rules/rules.go`.

## 2026-09-09 — A given is a mapping, and there is one operator

`given` is a YAML mapping of one target to the value it holds, so the colon is
the operator. `then` spells out the single operator, `should be`. `Assertion`
carries a target and a value and no operator field.

Three spellings used to be accepted — `is`, `=`, and `should be` — and the
counter app used all three, one of them in a scenario that had accidentally
written `counterStore.value is: 0` as a nested key. That parsed as a mapping,
`stringValue` returned "" for it, and the scenario ran with no given at all
without a word in the log. Reading the value as YAML rather than out of a
sentence is also what lets a list or a mapping be a given without a quoting
rule and a second parser.

Code: `behavior/rules/parse.go`.

## 2026-09-09 — A value the store cannot hold is an error

`dartLiteralForValue` fails when the value an assertion carries is not of the
store's type. `list(task)` is a real type: it maps to `List<dynamic>` and seeds
a list of Dart maps.

It used to fall back to a Dart string literal for anything it could not parse,
so a `given` of `[]` on a list store seeded the string `'[]'`. The test compiled,
ran, asserted against a string, and reported the scenario as covered. The
element is a map rather than a `Task` because models.yaml is not read yet;
`DartTypeFor` is the one place that has to learn class names when it is.

Code: `behavior/codegen/flutter/testcase_build.go`, `codegen/dart/layout.go`.

## 2026-09-08 — One scenario, one test, against the whole app

A scenario is never split by layer. Whatever its trigger, it becomes exactly one
test that pumps the composed page and drives it the way a user would.

Scenarios used to compile down to a Cubit unit test when their trigger was a
store action. Those tests passed while the button that was supposed to call the
Cubit was wired to nothing, so the suite was green and the app was dead.

Code: `behavior/codegen/flutter/testcase.go`, `core/plan/build.go`.

## 2026-09-08 — Ask once, with everything

The implement stage makes one request carrying the whole spec, every generated
test, and every file the model may write. Each repair iteration is one more
request carrying every failure at once.

Generating a wrapper at a time and then repairing a test at a time meant a
seven-scenario counter app made seventeen requests, each seeing one slice of the
problem. That is how the counter Cubit came back with placeholder `increment`
and `decrement` bodies: the request that wrote it had never been shown the tests
those methods had to satisfy. Repairing one failure at a time was worse — each
fix overwrote the file the previous one had just repaired, without seeing why.

Code: `behavior/codegen/flutter/implement.go`.

## 2026-09-08 — A wrapper composes the dumb widget; it does not re-render it

A wrapper instantiates the generated widget and passes the values and callbacks
that reach the store. The generated widget already exposes a parameter per
variable, per event, and per wired child, put there for exactly this purpose.

The deterministic wrapper generator used to walk the UI spec a second time and
rebuild the Scaffold, the Column and every child: 372 lines that were a near
copy of the widget renderer, so both had to agree about every widget in the
catalog. With an API key configured the model then threw all of it away and
wrote the twenty-line composition instead. Removing it also removed the wrapper
per button, which nothing could reference — a page instantiates its own
children, so it could never use them.

Code: `behavior/codegen/flutter/wrappers_render.go`.

## 2026-09-08 — Where a generated file goes is decided once

Paths and class names for generated code come from `codegen/dart`'s layout
rules. Nothing else restates them.

Six places used to each rebuild a piece: the planner wrote wrapper paths, the
pruner rebuilt them to decide what was stale, the implementer rebuilt them again
to decide what it owned, and the test builder rebuilt the import paths a third
time. Any two of them drifting produced a test importing a file nothing had
written.

Code: `codegen/dart/layout.go`.

## 2026-09-08 — The action a widget event runs comes from the spec, not from the values

`decrementButton.onPressed` runs `decrement`, read off the widget's name.

It used to be guessed by parsing the scenario's given and then values as
integers and comparing them. That works for counters and silently mislabels
everything else: every button on a non-numeric store was named `increment`.

Code: `behavior/rules/binding.go`.

## 2026-09-08 — A store action body is business logic, so a generator does not write it

The scaffolded Cubit declares its methods and throws `UnimplementedError`. The
bodies come from the behavior scenarios through the implement stage.

Hardcoding `increment` and `decrement` in the generator made the counter app
work and made every other app quietly wrong. It also pushed real rules into the
wrapper layer, where a generated wrapper reached through `cubit.emit` because
the Cubit had no method to call. Nothing is inferred from the store's type
either: a default `increment` on every numeric store put a method on the Cubit
that no scenario asked for, and hid the absence of the ones that were.

Code: `specs/data/codegen/flutter/store.go`.

## 2026-09-08 — A test with no interaction is not a test

An event with no known tester idiom is an error. A scenario whose `then` names
neither a store nor a widget is an error.

Both used to fall back to something. An unknown event produced an empty action,
so the test pumped the widget and asserted without ever interacting — it passed
whenever the initial state happened to match, and reported the scenario as
covered. An unresolvable `then` fell back to the store's value, writing a test
that asserted something the scenario never mentioned.

Code: `behavior/codegen/flutter/testcase_build.go`.

## 2026-09-08 — Find widgets by key, not by type

Generated widgets carry `key: Key("<name>")`, and generated tests find them that
way.

Finding by Flutter type fails the moment a page has two buttons: `tap()` reports
"ambiguously found multiple matching widgets" and every tap scenario in the spec
fails at once.

Code: `behavior/codegen/flutter/testcase_build.go`.

## 2026-09-08 — Generated output is marked, and stale output is pruned

Every generated file opens with `GENERATED BY METACODE`. After generation, files
under the directories this engine owns that carry the marker and were not
produced by this run are deleted.

Generation only ever wrote files, so renaming a widget or a scenario left the
old output on disk. Stale test files kept running and kept failing, which is how
one renamed widget turned into a list of failures for scenarios that no longer
existed. The marker is what makes the deletion safe: a hand-written file in the
same directory survives.

Code: `codegen/dart/prune.go`.

## 2026-09-08 — The bracket check has to read comments

The shape check applied to model output skips comments and string literals
before counting brackets.

A doc comment reading "seed a scenario's Given state" opens a string that never
closes, and every bracket after it stops counting. A correct file came back from
the model, failed the check, and was silently discarded three times in a row,
while the run reported the scaffolded placeholder as the model's work. A discard
is now logged as an error, because it means the model did the work and the
engine threw it away.

Code: `codegen/dart/validate.go`.

## 2026-09-08 — Map iteration is sorted everywhere it can reach output

Any map walk that can reach generated code, a warning, or planned work is
ordered.

Go randomizes map iteration on every execution, so an unordered walk produces
different bytes from identical specs. Reproducible output is what makes
generated files reviewable in a diff, and it is a precondition for the
lock-and-diff optimization.

Code: `order/order.go`.

## 2026-09-08 — Scenario names are prose, so file names are slugs

A scenario ID becomes a file name through one slug rule.

Leaving the prose in produced test files like `not decrements when is 0_test.dart`,
which every tool that takes a path had to be careful with, and which the Flutter
test output parser could not read back.

Code: `codegen/dart/layout.go`.

## 2026-09-08 — One target, assembled in cmd, behind a struct of functions

`run.Target` carries the generation stages, the implement constructor and the
test command. `cmd/metacode` is the only place that names Flutter.

It is a struct rather than an interface because there is one target today: an
interface would add a method set, a constructor and a name method without adding
a second implementation. Adding a language means writing a sibling assembly.
Three interfaces that did have exactly one implementation each — the wrapper
generator, the verifier, and the stage reporter — were removed for the same
reason. `Target.validate` exists because a stage left unset is a nil call in the
middle of a run: adding `NewImplementer` to the struct and forgetting it in the
assembly panicked with a line number instead of a name.

Code: `core/run/target.go`, `cmd/metacode/main.go`.
