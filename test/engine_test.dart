// The engine against its own small app, test/fixture_app/ (one of each
// feature: state, values, labels in two languages, every route type, a module
// embedded contained and not). Compiled here from its files, so nothing here
// depends on the real app (examples/my_own_app/ has its own tests in test/).

import 'dart:convert';
import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metacode/compiler/build.dart';
import 'package:metacode/engine/app.dart';
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
    Size size = const Size(800, 1000),
    bool selectableText = false,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final config = ProjectConfig.fromBundle(bundleOverride ?? bundle);
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

  testWidgets('a module embedded without contained opens over the whole app',
      (tester) async {
    await pump(tester);
    await tap(tester, find.text('Module sheet').last);
    expect(tester.getSize(find.byType(BottomSheet)).width, 800); // the window
    expect(moduleNavigator(tester).canPop(), isFalse);
    await tap(tester, find.text('Done'));
    expect(find.byType(BottomSheet), findsNothing);
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
