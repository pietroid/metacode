// Renders the app (examples/my_own_app/.generated/bundle.json: every app, modules
// included) through the engine + app_ui, and drives it with taps.
// Regenerate first: tool/check_engine.sh.

import 'dart:convert';
import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:metacode/engine/app.dart';
import 'package:metacode/engine/project_config.dart';
import 'package:metacode/engine/state_bloc.dart';

void main() {
  final bundle = jsonDecode(
      File('examples/my_own_app/.generated/bundle.json').readAsStringSync()) as Map;
  final styleYaml = Map<String, dynamic>.from(bundle['style'] as Map);

  // Real type and icons, so layout (and overflow) matches the app, not the
  // test font.
  setUpAll(() async {
    Future<void> load(String family, Iterable<String> files) async {
      final loader = FontLoader('packages/app_ui/$family');
      for (final f in files) {
        loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
      }
      await loader.load();
    }

    final files = Directory('packages/app_ui/fonts')
        .listSync(recursive: true)
        .map((f) => f.path)
        .where((p) => p.endsWith('.ttf'));
    for (final family in fontFamilies.where((f) => f != 'system')) {
      final prefix = '${family.replaceAll(' ', '')}-';
      await load(family, files.where((p) => p.split('/').last.startsWith(prefix)));
    }
    for (final w in ['Thin', 'Light', 'Regular', 'Bold', 'Fill']) {
      await load('Phosphor$w', files.where((p) => p.endsWith('Phosphor-$w.ttf')));
    }
  });

  /// Answers `core.api` requests in tests (the website makes none).
  final client = MockClient((request) async => http.Response('{}', 200));

  Future<StateBloc> pump(
    WidgetTester tester,
    Map<String, dynamic> state, {
    Size size = const Size(390, 844),
    Brightness brightness = Brightness.dark,
    Map<String, dynamic>? style,
    bool selectableText = false,
    String? waitlistAs,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // The ticker (marquee) loops forever; with reduced motion it stands still,
    // so pumpAndSettle can settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    // A fresh tree per pump: each app's program keeps its host and each
    // module starts from its own initial state.
    final config = ProjectConfig.fromBundle({
      ...bundle,
      'state': state,
      'style': ?style,
      // The bundle opens `waitlist` as a dialog; tests also open it as the
      // other route types, so each one is covered.
      if (waitlistAs != null)
        'navigation': {
          ...bundle['navigation'] as Map,
          'routes': {
            ...(bundle['navigation'] as Map)['routes'] as Map,
            'waitlist': {waitlistAs: 'WaitlistDialog'},
          },
        },
    });
    final bloc = StateBloc(config: config, initial: state);
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MetacodeApp(
        config: config,
        client: client,
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        selectableText: selectableText,
      ),
    ));
    return bloc;
  }

  // state/ (so new fields are always there), with a fresh hero and form.
  final yamlState = Map<String, dynamic>.from(bundle['state'] as Map);
  Map<String, dynamic> state() => {
        ...jsonDecode(jsonEncode(yamlState)) as Map<String, dynamic>,
        'idea': 'Remind me to water my plants',
        'buildStep': 0,
        'email': '',
        'waitlistStatus': 'idle',
        'waitlistCount': 1284,
      };

  /// Taps "Make my app" in the studio, below the hero.
  Future<void> tapMake(WidgetTester tester) async {
    final make = find.text('Make my app');
    await tester.ensureVisible(make);
    await tester.pumpAndSettle();
    await tester.tap(make);
  }

  testWidgets('a new bundle replaces the running app and keeps the state',
      (tester) async {
    final bloc = await pump(tester, state());
    await bloc.setState({...bloc.state, 'email': 'me@example.com'});
    Finder inBar(String text) =>
        find.descendant(of: find.byType(AppBar), matching: find.text(text));
    expect(inBar('Join waitlist'), findsOneWidget);

    // A new version: a changed label and a new state field.
    final labels = jsonDecode(jsonEncode(bundle['labels'])) as Map;
    (labels['en'] as Map)['joinWaitlistText'] = 'Count me in';
    final next = ProjectConfig.fromBundle({
      ...bundle,
      'state': {...state(), 'addedField': 7},
      'labels': labels,
    });
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MetacodeApp(
          config: next, client: client, themeMode: ThemeMode.dark),
    ));
    await tester.pump();

    expect(inBar('Join waitlist'), findsNothing);
    expect(inBar('Count me in'), findsOneWidget);
    expect(bloc.config, same(next));
    expect(bloc.state['email'], 'me@example.com');
    expect(bloc.state['addedField'], 7);

    // Actions run on the new version.
    await tapMake(tester);
    await tester.pump();
    expect(bloc.state['buildStep'], 1);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.pumpAndSettle();
    expect(bloc.state['buildStep'], 5);
  });

  testWidgets('the language picker switches every app, modules too',
      (tester) async {
    await pump(tester, state());
    Finder inBar(String text) =>
        find.descendant(of: find.byType(AppBar), matching: find.text(text));
    // The test device is en_US: English, automatically.
    expect(inBar('Join waitlist'), findsOneWidget);
    expect(inBar('EN'), findsOneWidget);
    expect(find.text('Today'), findsWidgets); // the food module

    await tester.tap(inBar('EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PT-BR').last);
    await tester.pumpAndSettle();

    expect(inBar('Entrar na lista'), findsOneWidget);
    expect(inBar('PT-BR'), findsOneWidget);
    expect(find.text('Criar meu app'), findsOneWidget);
    expect(find.text('Hoje'), findsWidgets);
    expect(Localizations.localeOf(tester.element(find.byType(AppBar))),
        const Locale('pt', 'BR'));
    // Material's own text follows.
    expect(
        MaterialLocalizations.of(tester.element(find.byType(AppBar)))
            .okButtonLabel,
        'OK');
  });

  testWidgets('hero: make my app walks the steps, then is ready', (tester) async {
    final bloc = await pump(tester, state());
    expect(find.text('MY OWN APP'), findsWidgets);
    expect(find.text('Designing your screens'), findsOneWidget);
    expect(find.text('Keep my app'), findsNothing);

    await tapMake(tester);
    await tester.pump();
    expect(bloc.state['buildStep'], 1);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.pumpAndSettle();
    expect(bloc.state['buildStep'], 5);
    expect(find.text('Keep my app'), findsOneWidget);
    expect(find.text('Make it again'), findsOneWidget);
  });

  testWidgets('hero: an idea chip fills the idea and builds', (tester) async {
    final bloc = await pump(tester, state());
    await tester.ensureVisible(find.text('Track my daily habits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Track my daily habits'));
    await tester.pump();
    expect(bloc.state['idea'], 'Track my daily habits');
    expect(bloc.state['appKind'], 'habits');
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.pumpAndSettle();
    expect(bloc.state['buildStep'], 5);
  });

  testWidgets('waitlist: joins from the section at the bottom', (tester) async {
    final bloc = await pump(tester, state());
    final field = find.widgetWithText(TextField, 'you@example.com');
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    final join = find.widgetWithText(FilledButton, 'Join waitlist');
    await tester.enterText(field, 'nope');
    await tester.ensureVisible(join);
    await tester.pumpAndSettle();
    await tester.tap(join);
    await tester.pump();
    expect(find.text("That email doesn't look right."), findsOneWidget);

    await tester.enterText(field, 'ada@example.com');
    await tester.tap(join);
    await tester.pump();
    expect(bloc.state['waitlistStatus'], 'joined');
    expect(find.text("We'll email ada@example.com when your spot opens."), findsOneWidget);
    expect(find.text('1,285 people are already on the list'), findsOneWidget);
  });

  testWidgets('waitlist: the dialog is 420 wide on desktop, inset on a phone',
      (tester) async {
    for (final (size, width) in [(const Size(1440, 900), 420.0), (const Size(390, 844), 310.0)]) {
      await pump(tester, state(), size: size);
      await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.text('Join waitlist')));
      await tester.pumpAndSettle();
      final material = find.descendant(of: find.byType(Dialog), matching: find.byType(Material)).first;
      expect(tester.getSize(material).width, width, reason: '$size');
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
    }
  });

  for (final (type, widget) in [('dialog', Dialog), ('bottomSheet', BottomSheet)]) {
    testWidgets('waitlist: the app bar button opens it as a $type', (tester) async {
      await pump(tester, state(), waitlistAs: type);
      await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.text('Join waitlist')));
      await tester.pumpAndSettle();
      expect(find.byType(widget), findsOneWidget);
      expect(find.descendant(of: find.byType(widget), matching: find.text('Get early access')),
          findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.byType(widget), findsNothing);
    });

    testWidgets('web/desktop: text is selectable, clicks still click (${type}s too)',
        (tester) async {
      final bloc = await pump(tester, state(), selectableText: true, waitlistAs: type);
      expect(find.byType(SelectionArea), findsOneWidget);
      // Plain text is in the selection; a button's label is not, and shows a
      // pointer.
      Finder clickableOf(Finder f) =>
          find.ancestor(of: f, matching: find.byType(Clickable));
      expect(clickableOf(find.text('Make my app')), findsOneWidget);
      expect(clickableOf(find.text('Designing your screens')), findsNothing);

      await tapMake(tester);
      await tester.pump();
      expect(bloc.state['buildStep'], 1);

      await tester.tap(find.descendant(
          of: find.byType(AppBar), matching: find.text('Join waitlist')));
      await tester.pumpAndSettle();
      expect(find.byType(widget), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.byType(widget), findsNothing);
    });
  }

  testWidgets('phone and desktop layouts render without overflow', (tester) async {
    for (final size in [const Size(360, 780), const Size(390, 844), const Size(820, 1180), const Size(1440, 900)]) {
      await pump(tester, {...state(), 'buildStep': 5}, size: size);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('the page renders with every bundled font, light and dark, without overflow',
      (tester) async {
    for (final family in fontFamilies) {
      for (final brightness in Brightness.values) {
        await pump(tester, state(),
            brightness: brightness,
            style: {
              ...styleYaml,
              'theme': brightness.name,
              'fonts': {'display': family, 'text': family},
            });
        expect(tester.takeException(), isNull, reason: '$family $brightness');
      }
    }
  });

  testWidgets('examples carousel: every slide renders on phone and desktop', (tester) async {
    for (final size in [const Size(360, 780), const Size(1440, 900)]) {
      for (var i = 0; i < 4; i++) {
        await tester.pumpWidget(const SizedBox()); // fresh tree, so the new state is used
        await pump(tester, {...state(), 'exampleIndex': i}, size: size);
        await tester.pumpAndSettle();
        expect(find.text(['Today', 'Guitar basics', 'November', 'Plant care'][i]), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'slide $i at $size');
      }
    }
  });

  testWidgets('examples carousel: arrows, chips and a mini app respond', (tester) async {
    final bloc = await pump(tester, {...state(), 'exampleIndex': 0});
    final next = find.byTooltip('Next');
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(bloc.state['exampleIndex'], 1);
    expect(find.text('Guitar basics'), findsOneWidget);

    await tester.tap(find.text('Plants'));
    await tester.pumpAndSettle();
    final water = find.byTooltip('Watered').first;
    await tester.ensureVisible(water);
    await tester.pumpAndSettle();
    await tester.tap(water);
    await tester.pumpAndSettle();
    // The plants module has its own state: Monstera is due again in 7 days.
    expect(find.text('In 7 days'), findsOneWidget);
    expect(bloc.state.containsKey('plants'), isFalse);
  });
}
