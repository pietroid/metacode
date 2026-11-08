// Layout check for any app: renders every app in the tree (the root, and each
// module as a parent shows it: the whole screen of a scaffold, contained)
// and every route of each (pages, sheets, dialogs) at
// phone, tablet and desktop sizes, from the initial state, and fails on any
// overflow or render error. Then each app's selected states (tests/*.yaml,
// collected in .generated/layout_states.json): that state over the initial
// one, on its initial page or the route it names, at every size. Knows
// nothing about the app; run by tool/check.sh:
//
//   flutter test tool/layout_test.dart [--dart-define=METACODE_APP=<folder>]
//
// Needs <folder>/.generated/bundle.json (dart run tool/metacode.dart).

import 'dart:async';
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
import 'package:metacode/engine/core_host.dart';
import 'package:metacode/engine/project_config.dart';
import 'package:metacode/engine/state_bloc.dart';

const appDir = String.fromEnvironment('METACODE_APP',
    defaultValue: 'examples/my_own_app');

const sizes = {
  'phone': Size(360, 780),
  'large phone': Size(390, 844),
  'tablet': Size(820, 1180),
  'desktop': Size(1440, 900),
};

// No real requests.
final client = MockClient((_) async => http.Response('{}', 200));

void main() {
  final bundle = jsonDecode(
          File('$appDir/.generated/bundle.json').readAsStringSync())
      as Map<String, dynamic>;
  final statesFile = File('$appDir/.generated/layout_states.json');
  final testStates = statesFile.existsSync()
      ? jsonDecode(statesFile.readAsStringSync()) as Map<String, dynamic>
      : const <String, dynamic>{};

  // The real type and icons, so text wraps (and overflows) as in the app,
  // not as in the test font.
  setUpAll(() async {
    Future<void> load(String family, Iterable<String> files) async {
      final loader = FontLoader('packages/app_ui/$family');
      for (final f in files) {
        loader.addFont(
            Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
      }
      await loader.load();
    }

    final files = Directory('packages/app_ui/fonts')
        .listSync(recursive: true)
        .map((f) => f.path)
        .where((p) => p.endsWith('.ttf'));
    for (final family in fontFamilies.where((f) => f != 'system')) {
      final prefix = '${family.replaceAll(' ', '')}-';
      await load(
          family, files.where((p) => p.split('/').last.startsWith(prefix)));
    }
    for (final w in ['Thin', 'Light', 'Regular', 'Bold', 'Fill']) {
      await load(
          'Phosphor$w', files.where((p) => p.endsWith('Phosphor-$w.ttf')));
    }
  });

  /// Every app in the tree, by label: `root`, `modules/food`, ...
  Map<String, Map<String, dynamic>> apps(Map<String, dynamic> node,
          [String label = 'root']) =>
      {
        label: node,
        for (final MapEntry(:key, :value)
            in ((node['modules'] as Map?) ?? {}).entries)
          ...apps(Map<String, dynamic>.from(value as Map),
              label == 'root' ? 'modules/$key' : '$label/modules/$key'),
      };

  for (final MapEntry(key: label, value: node) in apps(bundle).entries) {
    final states = (testStates[label] as Map?) ?? const {};
    for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
      testWidgets('$label on a $sizeName: every route lays out',
          (tester) async {
        final (config, host) = await render(
            tester, bundle, label, node, size, '$label, initial, $sizeName');
        for (final route in config.navigation.routes.keys) {
          if (route == config.navigation.initial) continue;
          unawaited(host.push(route));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$label, route $route, $sizeName');
          await host.call('navigator.pop', {});
          await tester.pumpAndSettle();
        }
      });

      for (final MapEntry(key: name, value: test as Map) in states.entries) {
        testWidgets('$label, test state $name, on a $sizeName: lays out',
            (tester) async {
          final where = '$label, test state $name, $sizeName';
          final state = {
            ...(node['state'] as Map? ?? const {}),
            ...(test['state'] as Map),
          };
          final (_, host) = await render(
              tester, bundle, label, {...node, 'state': state}, size, where);
          final route = test['route'] as String?;
          if (route != null) {
            unawaited(host.push(route));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: '$where, route $route');
          }
        });
      }
    }
  }
}

/// Pumps the app [label] ([node], with the state it holds) at [size] on its
/// initial page, expects no render error ([where] names the case), and
/// returns its config and host, ready to push routes.
Future<(ProjectConfig, CoreHost)> render(
    WidgetTester tester,
    Map<String, dynamic> bundle,
    String label,
    Map<String, dynamic> node,
    Size size,
    String where) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // Endless animations (a marquee) stand still, so pumpAndSettle ends.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  // A module is shown by a host root: a scaffold whose body is the module,
  // contained (so its routes open over that body).
  final root = ProjectConfig.fromBundle(label == 'root'
      ? node
      : {
          ...bundle,
          'ui': {
            'widgets': {
              'LayoutHost': {
                'scaffold': {
                  'body': {
                    'module': {'name': 'module', 'contained': true}
                  }
                }
              },
            },
          },
          'navigation': {
            'initial': 'home',
            'routes': {'home': 'LayoutHost'},
          },
          'modules': {'module': node},
        });
  final config = label == 'root' ? root : root.modules['module']!;
  final bloc = StateBloc(config: root, initial: root.initialState);
  await tester.pumpWidget(BlocProvider.value(
    value: bloc,
    // From the initial state: app.yaml `start:` actions don't run.
    child: MetacodeApp(config: root, client: client, runStart: false),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: where);

  final host = config.program.host as CoreHost;
  if (label != 'root') {
    // Routes open in the module's navigator, as a tap in it does.
    host.actionFrom(tester.element(find.byType(Navigator).last));
  }
  return (config, host);
}
