// Renders metacode/ui.yaml through the engine + app_ui with the compiled
// program and the app's style.yaml, and drives it with taps.
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
import 'package:metacode/engine/navigation.dart';
import 'package:metacode/engine/program.dart';
import 'package:metacode/engine/project_config.dart';
import 'package:metacode/engine/state_bloc.dart';
import 'package:yaml/yaml.dart';

void main() {
  final program = MetacodeProgram(
    ByteData.sublistView(File('metacode/generated/program.evc').readAsBytesSync()),
    jsonDecode(File('metacode/generated/manifest.json').readAsStringSync()),
  );
  final ui = yamlToDart(loadYaml(File('metacode/ui.yaml').readAsStringSync()));
  final appStyle =
      resolveStyle(loadYaml(File('metacode/style.yaml').readAsStringSync()));
  final navigation = Navigation.parse(
      loadYaml(File('metacode/navigation.yaml').readAsStringSync()))!;

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

  /// Answers `core.api` requests in tests (the dollar rate api).
  var requests = <String>[];
  final client = MockClient((request) async {
    requests.add('${request.method} ${request.url}');
    return http.Response(
        '{"time_last_update_utc":"Fri, 06 Nov 2026","rates":{"BRL":5.4321}}', 200);
  });

  Future<StateBloc> pump(
    WidgetTester tester,
    Map<String, dynamic> state, {
    Brightness brightness = Brightness.light,
    Map<String, dynamic>? style,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    requests = [];
    final config = ProjectConfig(
      projectName: 'test',
      description: '',
      ui: ui,
      initialState: state,
      program: program,
      style: style ?? appStyle,
      navigation: navigation,
    );
    final bloc = StateBloc(config: config, initial: state);
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MetacodeApp(
        config: config,
        client: client,
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      ),
    ));
    return bloc;
  }

  Map<String, dynamic> state({String page = 'finances'}) => {
        'page': page,
        'entries': [
          {'title': 'Salary', 'amount': 3200, 'kind': 'income', 'date': '2026-11-01'},
          {'title': 'Rent', 'amount': 1100, 'kind': 'expense', 'date': '2026-11-02'},
        ],
        'goals': [
          {'name': 'Laptop', 'target': 1500, 'saved': 400},
        ],
        'profile': {
          'name': 'Ada Lovelace',
          'email': 'ada@example.com',
          'currency': r'$',
          'notifications': true,
        },
        'entryTitle': '',
        'entryAmount': '',
        'entryKind': 'income',
        'goalName': '',
        'goalTarget': '',
        'contribution': '10',
        'dollarRate': 0,
        'dollarRateStatus': 'idle',
        'dollarRateUpdated': '',
      };

  testWidgets('finances: lists entries and adds one', (tester) async {
    final bloc = await pump(tester, state());
    expect(find.text('Finances'), findsWidgets);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Coffee');
    await tester.enterText(find.byType(TextField).at(1), '4.5');
    await tester.tap(find.text('Expense'));
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pump();

    final entries = bloc.state['entries'] as List;
    expect(entries.length, 3);
    expect(entries.last['title'], 'Coffee');
    expect(entries.last['kind'], 'expense');
    expect(bloc.state['entryTitle'], '');
  });

  testWidgets('navigation switches pages', (tester) async {
    final bloc = await pump(tester, state());
    await tester.tap(find.text('Goals'));
    await tester.pump();
    expect(bloc.state['page'], 'goals');
    expect(find.text('Laptop'), findsOneWidget);
  });

  testWidgets('menu: the labeled toggle flips notifications', (tester) async {
    final bloc = await pump(tester, state(page: 'menu'));
    expect(find.text('Ada Lovelace'), findsWidgets);
    await tester.tap(find.text('Notifications'));
    await tester.pump();
    expect(bloc.state['profile']['notifications'], false);
  });

  testWidgets('dollar rate: opens a bottom sheet and loads the rate', (tester) async {
    final bloc = await pump(tester, state(page: 'menu'));
    await tester.ensureVisible(find.text('Dollar rate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dollar rate'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(requests, ['GET https://open.er-api.com/v6/latest/USD']);
    expect(bloc.state['dollarRateStatus'], 'loaded');
    expect(find.text(r'1 USD = R$ 5.43'), findsOneWidget);

    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(requests.length, 2);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('reset asks in a dialog first', (tester) async {
    final bloc = await pump(tester, state(page: 'menu'));
    await tester.ensureVisible(find.text('Reset all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset all data'));
    await tester.pumpAndSettle();
    expect(find.text('Reset all data?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect((bloc.state['entries'] as List).length, 2);

    await tester.tap(find.text('Reset all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(bloc.state['entries'], isEmpty);
    expect(bloc.state['goals'], isEmpty);
  });

  testWidgets('shows the empty state', (tester) async {
    await pump(tester, {...state(), 'entries': []});
    expect(find.text('No transactions yet'), findsOneWidget);
  });

  testWidgets('every page renders with every bundled font, dark, without overflow',
      (tester) async {
    for (final family in fontFamilies) {
      for (final page in ['finances', 'goals', 'menu']) {
        await pump(tester, state(page: page),
            brightness: Brightness.dark,
            style: resolveStyle({
              'fonts': {'display': family, 'text': family},
            }));
        expect(tester.takeException(), isNull, reason: '$family $page');
      }
    }
  });
}
