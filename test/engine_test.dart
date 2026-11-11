// The engine against its own small app, test/fixture_app/ (one of each
// feature: state, values, labels in two languages, every route type, a module
// as a mini app and in parts, a dynamic module). Compiled here from its files, so nothing here
// depends on the real app (examples/my_own_app/ has its own tests in test/).

import 'dart:convert';
import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metacode/compiler/build.dart';
import 'package:metacode/engine/app.dart';
import 'package:metacode/engine/core_host.dart';
import 'package:metacode/engine/project_config.dart';
import 'package:metacode/engine/state_bloc.dart';
import 'package:metacode/files/project_files.dart';

const fixtureDir = 'test/fixture_app';

/// test/fixture_app/'s sources, as `{path: contents}`.
Map<String, String> fixtureFiles() => {
      for (final f in Directory(fixtureDir).listSync(recursive: true))
        if (f is File &&
            ProjectFiles.isSource(f.path.substring(fixtureDir.length + 1)))
          f.path.substring(fixtureDir.length + 1): f.readAsStringSync(),
    };

/// The fixture's bundle, compiled like the CLI does.
Map<String, dynamic> compileFixture() {
  final result =
      build(ProjectFiles.fromSnapshot(fixtureFiles()), path: fixtureDir);
  expect(result.issues.errors, isEmpty);
  return jsonDecode(result.bundle!) as Map<String, dynamic>;
}

void main() {
  late Map<String, dynamic> bundle;
  setUpAll(() => bundle = compileFixture());

  Future<StateBloc> pump(
    WidgetTester tester, {
    Map<String, dynamic>? bundleOverride,
    ProjectConfig? configOverride,
    Size size = const Size(800, 1600),
    bool selectableText = false,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final config =
        configOverride ?? ProjectConfig.fromBundle(bundleOverride ?? bundle);
    final bloc = StateBloc(config: config, initial: config.initialState);
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MetacodeApp(
        config: config,
        selectableText: selectableText,
        themeMode:
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      ),
    ));
    await tester.pumpAndSettle();
    return bloc;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// The contained module's navigator (the one around its first "Hello").
  NavigatorState moduleNavigator(WidgetTester tester) =>
      tester.state<NavigatorState>(find
          .ancestor(of: find.text('Hello').first, matching: find.byType(Navigator))
          .first);

  testWidgets('renders labels and values; actions change the state through emit',
      (tester) async {
    final bloc = await pump(tester);
    expect(find.text('Fixture'), findsOneWidget);
    expect(find.text('Count 0'), findsOneWidget);
    await tap(tester, find.text('Add'));
    expect(find.text('Count 1'), findsOneWidget);
    expect(bloc.state['count'], 1);
  });

  testWidgets('a value reruns only when a state field it reads changes',
      (tester) async {
    final config = ProjectConfig.fromBundle(bundle);
    await pump(tester, configOverride: config);
    final runs = config.program.runs;
    int ran(String name) => runs[name] ?? 0;
    final count = ran('countText'), odd = ran('isOdd'), votes = ran('votesText');
    // Rename changes only the nickname: countText and isOdd (count, isOdd
    // through the shared countOf) keep their results, votesText reruns.
    await tap(tester, find.text('Rename'));
    expect(find.text('Votes: 0 grace'), findsOneWidget);
    expect(ran('votesText'), greaterThan(votes));
    expect(ran('countText'), count);
    expect(ran('isOdd'), odd);
    await tap(tester, find.text('Add'));
    expect(find.text('Count 1'), findsOneWidget);
    expect(find.text('Odd'), findsOneWidget);
    expect(ran('countText'), greaterThan(count));
    expect(ran('isOdd'), greaterThan(odd));
  });

  testWidgets('remote.<name>() without a backend runs the remote action on '
      'the device; shared and remote fields show at once', (tester) async {
    final bloc = await pump(tester);
    expect(find.text('Votes: 0 '), findsOneWidget);
    await tap(tester, find.text('Vote'));
    expect(bloc.state['votes'], 1, reason: '${bloc.state}');
    expect(find.text('Votes: 1 ada'), findsOneWidget);
    expect(bloc.state.containsKey('voters'), isFalse); // system: not here
    // A local action emitting a remote field: applied at once.
    await tap(tester, find.text('Rename'));
    expect(find.text('Votes: 1 grace'), findsOneWidget);
  });

  testWidgets('components take parameters, passed on through components',
      (tester) async {
    final bloc = await pump(tester);
    // MainPage -> Tag {label: tagged, tap: increment} -> Badge {text: .label,
    // tap: .tap, color: primary}.
    await tap(tester, find.text('Tagged'));
    expect(bloc.state['count'], 1);
  });

  testWidgets('an @Animated value eases on a ticker; the state switches at once',
      (tester) async {
    final bloc = await pump(tester);
    // Swatch {index: 1}: container color `swatch`, black when count == 1.
    Color swatch() => tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.borderRadius == BorderRadius.circular(7))
        .color!;
    expect(swatch(), const Color(0xFFFFFFFF));

    await tester.tap(find.text('Add'));
    await tester.pump(); // the state changes, the ticker starts
    expect(bloc.state['count'], 1);
    expect(swatch(), const Color(0xFFFFFFFF));
    await tester.pump(const Duration(milliseconds: 50)); // halfway, linear
    final mid = swatch();
    expect(mid.r, closeTo(0.5, 0.05));
    expect(bloc.state['count'], 1); // in-between frames never touch the state
    await tester.pumpAndSettle();
    expect(swatch(), const Color(0xFF000000));

    // Interrupted: eases back from where it is, not from black.
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(swatch(), const Color(0xFFFFFFFF));
  });

  testWidgets('an @Animated number fades a container and types a text out; '
      'reverseMs: 0 drops it at once', (tester) async {
    await pump(tester);
    // container {opacity: shown, child: text {value: typed, reveal: shown}};
    // shown is 1 while count == 1.
    double opacity() => tester
        .widget<Opacity>(find.ancestor(
            of: find.text('Typed text', findRichText: true),
            matching: find.byType(Opacity)))
        .opacity;
    String visible() {
      final span = tester
          .widget<RichText>(find.text('Typed text', findRichText: true))
          .text as TextSpan;
      final shown = span.children!.first as TextSpan;
      return shown.children!.first.toPlainText();
    }

    expect(opacity(), 0);
    expect(visible(), '');
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(opacity(), closeTo(0.5, 0.05));
    expect(visible(), 'Typed');
    await tester.pumpAndSettle();
    expect(find.text('Typed text'), findsOneWidget); // whole: a plain Text

    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(opacity(), 0);
  });

  testWidgets('match/if with fade: the old case fades out, then the new one in',
      (tester) async {
    await pump(tester);
    // if {condition: isOdd, then: Parity, else: Parity, fade: 200}; Parity
    // shows the `parity` value, which reads the same count.
    double opacityOf(String text) {
      final fade = tester.widget<FadeTransition>(find
          .ancestor(of: find.text(text), matching: find.byType(FadeTransition))
          .first);
      return fade.opacity.value;
    }

    expect(find.text('Even'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50)); // first half: out
    expect(opacityOf('Even'), inExclusiveRange(0, 1));
    expect(opacityOf('Odd'), 0);
    // The leaving branch is frozen: it still says Even, not the new Odd.
    expect(find.text('Even'), findsOneWidget);
    expect(find.text('Odd'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100)); // second half: in
    expect(opacityOf('Odd'), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.text('Even'), findsNothing);
    expect(find.text('Odd'), findsOneWidget);
  });

  testWidgets('an icon prop takes a value returning an icon name',
      (tester) async {
    await pump(tester);
    bool shows(String name) => find
        .byWidgetPredicate((w) =>
            w is Icon && phosphorIcons.values.any((m) => m[name] == w.icon))
        .evaluate()
        .isNotEmpty;
    expect(shows('close'), isTrue);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(shows('check'), isTrue);
    expect(shows('close'), isFalse);
  });

  testWidgets("app.yaml's start action runs when the app starts",
      (tester) async {
    final bloc = await pump(tester);
    expect(bloc.state['started'], true);
  });

  group('@Animated is checked', () {
    const file = 'app/views/values/swatch.dart';
    List<String> errors(String from, String to) {
      final source = fixtureFiles()[file]!;
      expect(source, contains(from));
      return build(
              ProjectFiles.fromSnapshot(
                  {...fixtureFiles(), file: source.replaceFirst(from, to)}),
              path: fixtureDir)
          .issues
          .errors;
    }

    test('an unknown curve', () {
      expect(errors("curve: 'linear'", "curve: 'wobbly'"),
          contains(contains('curve one of linear')));
    });
    test('a result that cannot ease', () {
      expect(
          errors('String swatch(State state, int index) =>\n'
              "    state.count == index ? '#000000' : '#FFFFFF';",
              'bool swatch(State state, int index) => state.count == index;'),
          contains(contains('return a color (String) or a number')));
    });
  });

  group('component parameters are checked', () {
    List<String> errors(Map<String, String> changes) => build(
            ProjectFiles.fromSnapshot({...fixtureFiles(), ...changes}),
            path: fixtureDir)
        .issues
        .errors;
    const main = 'app/views/pages/main_page.yaml';
    String mainWith(String from, String to) {
      final source = fixtureFiles()[main]!;
      expect(source, contains(from));
      return source.replaceFirst(from, to);
    }

    test('a missing argument', () {
      expect(errors({main: mainWith('tap: increment}', '}')}),
          [contains('missing tap:')]);
    });
    test('an unknown argument', () {
      expect(errors({main: mainWith('tap: increment}', 'tap: increment, x: 1}')}),
          [contains('Tag has no .x')]);
    });
    test('an argument of the wrong kind', () {
      expect(errors({main: mainWith('tap: increment}', 'tap: tagged}')}),
          [contains('"tagged" is not an action')]);
    });
    test('a component called without its arguments', () {
      expect(errors({main: mainWith('Tag: {label: tagged, tap: increment}', 'Tag')}),
          [contains('Tag needs arguments')]);
    });
    test('a page with parameters', () {
      expect(errors({main: mainWith('text: countText', 'text: .count')}),
          [contains('a page has no parameters (.count)')]);
    });
  });

  group('shared helpers, test states and state hints', () {
    BuildResult buildWith(Map<String, String> changes) => build(
        ProjectFiles.fromSnapshot({...fixtureFiles(), ...changes}),
        path: fixtureDir);

    test('a shared helper is bundled, not a value, and indexed', () {
      final result = buildWith({});
      expect(result.issues.errors, isEmpty);
      final manifest = (jsonDecode(result.bundle!) as Map)['manifest'] as Map;
      expect(manifest['bindings'], isNot(contains('withLabel')));
      final index = result.outputs['.generated/INDEX.md'] as String;
      expect(index, contains('## Shared'));
      expect(index, contains('**withLabel(String label, num n) → String**'));
      expect(index, contains('used by: countText'));
    });
    test("each value's reads are in the manifest, through shared helpers; "
        'a value using the whole state has none', () {
      Map reads(BuildResult r) =>
          ((jsonDecode(r.bundle!) as Map)['manifest'] as Map)['reads'] as Map;
      final plain = reads(buildWith({}));
      expect(plain['countText'], ['count']);
      expect(plain['isOdd'], ['count']); // through countOf(state)
      expect(plain['votesText'], ['nickname', 'voteError', 'votes']);
      for (final body in [
        'state.copyWith(count: 1).count.round().isOdd',
        '_odd(state)', // a private helper: followed (none here: whole)
      ]) {
        final r = buildWith({
          'app/views/values/is_odd.dart': '''
// isOdd: whole state.
import '../../../.generated/state.dart';

bool _odd(State s) => '\$s'.isEmpty;

bool isOdd(State state) => $body;
''',
        });
        expect(r.issues.errors, isEmpty, reason: body);
        expect(reads(r).containsKey('isOdd'), isFalse, reason: body);
      }
    });
    test('a shared file holds one public function, named after it', () {
      expect(
          buildWith({
            'app/views/values/shared/with_label.dart':
                'String withLabel(String l) => l;\nString other() => "";\n',
          }).issues.errors,
          [contains('exactly one public function (found 2)')]);
      expect(
          buildWith({
            'app/actions/shared/wrong_name.dart': 'String rightName() => "";\n',
          }).issues.errors,
          [contains('named after its function: right_name.dart')]);
    });
    test('test states reach the layout check, checked against the model', () {
      final result = buildWith({});
      final states = jsonDecode(
          result.outputs['.generated/layout_states.json'] as String) as Map;
      expect(states['root']['bigCount'],
          {'state': {'count': 1234567890}, 'route': 'details'});
      expect(
          buildWith({
            'tests/big_count.yaml':
                'bigCount:\n  state: {count: lots}\n  route: nowhere\n',
          }).issues.errors,
          [
            allOf(contains('tests/big_count.yaml'), contains('expected a number')),
            contains('"nowhere" is not a route'),
          ]);
    });
    test('an unquoted comma in a flow map gets a hint', () {
      expect(
          buildWith({
            'app.yaml': 'name: fixture\nstate:\n'
                '  ephemeral: {voteError: ""}\n'
                '  local: {count: 1, tiny: {files: [], folders: []}, started: false, a b}\n'
                '  remote: {nickname: ""}\n'
                '  system: {voters: []}\n'
                '  shared: {votes: 0}\n',
          })
              .issues
              .errors,
          [contains('an unquoted comma')]);
    });
  });

  testWidgets('a module has its own state', (tester) async {
    final bloc = await pump(tester);
    // Both embeds run the same module, so they show the same state.
    expect(find.text('Taps 0'), findsNWidgets(2));
    await tap(tester, find.text('Tap').first);
    expect(find.text('Taps 1'), findsNWidgets(2));
    expect(bloc.state['count'], 0);
    expect(bloc.state.containsKey('counter'), isFalse);
  });

  testWidgets('a new bundle replaces the running app and keeps the state',
      (tester) async {
    final bloc = await pump(tester);
    await tap(tester, find.text('Add'));

    final labels = jsonDecode(jsonEncode(bundle['labels'])) as Map;
    (labels['en'] as Map)['add'] = 'Plus one';
    final next = ProjectConfig.fromBundle({
      ...bundle,
      'state': {...bundle['state'] as Map, 'addedField': 7},
      'labels': labels,
    });
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MetacodeApp(config: next),
    ));
    await tester.pump();

    expect(find.text('Add'), findsNothing);
    expect(bloc.config, same(next));
    expect(bloc.state['count'], 1);
    expect(bloc.state['addedField'], 7);
    // Actions run on the new version.
    await tap(tester, find.text('Plus one'));
    expect(bloc.state['count'], 2);
  });

  testWidgets('core.locale.set switches every app, modules too', (tester) async {
    await pump(tester);
    expect(find.text('Hello'), findsNWidgets(2));
    await tap(tester, find.text('Portuguese'));
    expect(find.text('Contagem 0'), findsOneWidget);
    expect(find.text('Olá'), findsNWidgets(2));
    final context = tester.element(find.byType(AppBar));
    expect(Localizations.localeOf(context), const Locale('pt', 'BR'));
    expect(MaterialLocalizations.of(context).okButtonLabel, 'OK');
  });

  testWidgets('core.theme.set switches the whole app to dark', (tester) async {
    await pump(tester);
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(AppBar))).brightness;
    expect(brightness(), Brightness.light);
    await tap(tester, find.text('Dark'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
  });

  for (final (button, type) in [
    ('Details', DetailsLike.page),
    ('Sheet', DetailsLike.sheet),
    ('Dialog', DetailsLike.dialog),
  ]) {
    testWidgets('opens a ${type.name} route and closes it', (tester) async {
      await pump(tester);
      await tap(tester, find.text(button));
      expect(find.byType(type.widget), findsOneWidget);
      // The route follows the state.
      expect(find.text('Count 0'), findsNWidgets(type == DetailsLike.page ? 1 : 2));
      await tap(tester, find.text('Close'));
      expect(find.byType(type.widget), type == DetailsLike.page ? findsOneWidget : findsNothing);
      expect(find.text('Details').hitTestable(), findsOneWidget); // back home
    });
  }

  testWidgets('a bottom sheet grows with its content up to 90% of the screen',
      (tester) async {
    await pump(tester);
    await tap(tester, find.text('Sheet'));
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    final window = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(sheet.constraints?.maxHeight, window.height * 0.9);
  });

  testWidgets('a contained module opens its routes inside its box',
      (tester) async {
    await pump(tester);
    final box = tester.getRect(find.byType(Navigator).at(1));
    expect(box.size, const Size(300, 300));

    await tap(tester, find.text('Module sheet').first);
    final sheet = tester.getRect(find.byType(BottomSheet));
    expect(box.contains(sheet.topLeft) &&
        box.contains(sheet.bottomRight - const Offset(1, 1)), isTrue,
        reason: '$sheet in $box');
    expect(moduleNavigator(tester).canPop(), isTrue);

    // Its actions pop its own navigator.
    await tap(tester, find.text('Done'));
    expect(find.byType(BottomSheet), findsNothing);
    expect(moduleNavigator(tester).canPop(), isFalse);
  });

  testWidgets('core.modules.reset starts a module over', (tester) async {
    await pump(tester);
    await tap(tester, find.text('Tap').first);
    await tap(tester, find.text('Module sheet').first);
    expect(moduleNavigator(tester).canPop(), isTrue);
    await tap(tester, find.text('Reset'));
    expect(find.text('Taps 0'), findsNWidgets(2));
    expect(find.byType(BottomSheet), findsNothing);
    expect(moduleNavigator(tester).canPop(), isFalse);
  });

  testWidgets('a module\'s page used inline opens its routes over the whole app',
      (tester) async {
    await pump(tester);
    await tap(tester, find.text('Module sheet').last);
    expect(tester.getSize(find.byType(BottomSheet)).width, 800); // the window
    expect(moduleNavigator(tester).canPop(), isFalse);
    await tap(tester, find.text('Done'));
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('<module>.<name>: a module\'s action, value and component, on '
      'its own state', (tester) async {
    final bloc = await pump(tester);
    expect(find.text('Doubled 0'), findsOneWidget);
    // counter.Greeting {name: greet}: the argument is the module's label.
    expect(find.text('Greetings'), findsOneWidget);
    await tap(tester, find.text('Tap the counter'));
    expect(find.text('Taps 1'), findsNWidgets(2));
    // A value of the module, read by this app's page, follows its state.
    expect(find.text('Doubled 2'), findsOneWidget);
    expect(bloc.state['count'], 0);
  });

  testWidgets('core.modules.<name> runs a module\'s action and reads its value '
      'from code', (tester) async {
    final bloc = await pump(tester);
    await tap(tester, find.text('Tap').first);
    await tap(tester, find.text('Sync'));
    expect(find.text('Taps 2'), findsNWidgets(2));
    expect(bloc.state['count'], 2);
  });

  testWidgets('a route may open a module\'s page', (tester) async {
    final bloc = await pump(tester);
    final host = bloc.config.program.host as CoreHost;
    final pushed = host.push('counterHome');
    await tester.pumpAndSettle();
    expect(find.text('Hello').hitTestable(), findsOneWidget);
    await tap(tester, find.text('Tap').hitTestable());
    expect(find.text('Taps 1').hitTestable(), findsOneWidget);
    host.navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    await pushed;
  });

  group('a dynamic module (miniApp: {project: ..})', () {
    /// Lets the compile (a real isolate) finish, until [finder] shows.
    Future<void> waitFor(WidgetTester tester, Finder finder) async {
      for (var i = 0; i < 200 && finder.evaluate().isEmpty; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
      }
      expect(finder, findsWidgets);
    }

    /// The fixture's `tiny` project with the file at [path] replaced.
    Map<String, dynamic> edit(Map<String, dynamic> project, List<String> path,
        String content) {
      final copy = jsonDecode(jsonEncode(project)) as Map<String, dynamic>;
      var folder = copy;
      for (final name in path.take(path.length - 1)) {
        folder = (folder['folders'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((f) => f['name'] == name);
      }
      final file = (folder['files'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((f) => f['name'] == path.last);
      file['content'] = content;
      return copy;
    }

    testWidgets('runs the project in the state, sandboxed, and reloads in '
        'place (state kept) when it changes', (tester) async {
      final bloc = await pump(tester);
      await waitFor(tester, find.text('Tiny heading'));
      expect(find.text('Tiny n 0'), findsOneWidget);
      await tap(tester, find.text('Bump'));
      expect(find.text('Tiny n 1'), findsOneWidget);
      // Its state is its own.
      expect(bloc.state.containsKey('n'), isFalse);
      // It can't change the app's theme (or language).
      await tap(tester, find.text('Go dark'));
      expect(Theme.of(tester.element(find.byType(AppBar).first)).brightness,
          Brightness.light);

      final tiny = bloc.state['tiny'] as Map<String, dynamic>;
      await bloc.setState({
        ...bloc.state,
        'tiny': edit(tiny, ['app', 'views', 'labels', 'en.yaml'],
            'en:\n  heading: Edited heading\n  bumpText: Bump\n  goDarkText: Go dark\n'),
      });
      await waitFor(tester, find.text('Edited heading'));
      expect(find.text('Tiny n 1'), findsOneWidget); // state kept

      // A version that doesn't compile: the last one keeps running, with
      // the error over it.
      final edited = bloc.state['tiny'] as Map<String, dynamic>;
      await bloc.setState({
        ...bloc.state,
        'tiny': edit(edited, ['app', 'views', 'pages', 'main_page.yaml'],
            'MainPage:\n  text: count\n  column: []\n'),
      });
      await waitFor(tester, find.textContaining('a widget is a single key'));
      expect(find.text('Edited heading'), findsOneWidget);
    });
  });

  testWidgets('web/desktop: text is selectable, clicks still click',
      (tester) async {
    final bloc = await pump(tester, selectableText: true);
    expect(find.byType(SelectionArea), findsOneWidget);
    Finder clickableOf(Finder f) =>
        find.ancestor(of: f, matching: find.byType(Clickable));
    expect(clickableOf(find.text('Add')), findsOneWidget);
    expect(clickableOf(find.text('Count 0')), findsNothing);
    await tap(tester, find.text('Add'));
    expect(bloc.state['count'], 1);
    await tap(tester, find.text('Dialog'));
    expect(clickableOf(find.text('Close')), findsOneWidget);
  });

  testWidgets('renders with every bundled font, light and dark', (tester) async {
    // The fixture has no style/: the default one, with each font.
    const style = metacodeStyle;
    for (final family in fontFamilies) {
      for (final brightness in Brightness.values) {
        await pump(tester,
            brightness: brightness,
            bundleOverride: {
              ...bundle,
              'style': {
                ...style,
                'theme': brightness.name,
                'fonts': {'display': family, 'text': family},
              },
            });
        expect(tester.takeException(), isNull, reason: '$family $brightness');
      }
    }
  });
}

/// The fixture's route types and the widget each opens.
enum DetailsLike {
  page(Scaffold),
  sheet(BottomSheet),
  dialog(Dialog);

  final Type widget;
  const DetailsLike(this.widget);
}
