// The compiler and the engine in a browser (dart2js), as the web app runs
// them: flutter test --platform chrome test/web
// Needs fixture.g.dart (dart run tool/metacode.dart, then
// dart run tool/web_fixture.dart): the project's files and the bundle the
// CLI compiled.
@TestOn('browser')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:metacode/compiler/build.dart';
import 'package:metacode/engine/live_project.dart';
import 'package:metacode/engine/project_config.dart';
import 'package:metacode/engine/state_bloc.dart';
import 'package:metacode/engine/state_store.dart';
import 'package:metacode/files/local_storage_project_files.dart';
import 'package:metacode/files/project_files.dart';
import 'package:web/web.dart' as web;

import 'fixture.g.dart';

const projectDir = 'examples/my_own_app';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final seed = jsonDecode(filesJson) as Map;
  const cliBundle = bundleJson;

  test('compiles the project exactly as the CLI does', () {
    final result = build(ProjectFiles.fromSnapshot(seed), path: projectDir);
    expect(result.issues.errors, isEmpty);
    // The same data; JS writes the double 1.0 as 1, so compare it decoded.
    // The bytecode (base64 in "program") must be identical.
    expect(jsonDecode(result.bundle!), jsonDecode(cliBundle));
  });

  test('runs the compiled program: every value of every app', () async {
    final live = LiveProject(ProjectFiles.fromSnapshot(seed), path: projectDir);
    final config = (await live.compile())!;
    void check(ProjectConfig app) {
      for (final name in app.program.bindings) {
        expect(() => app.program.binding(name, app.initialState, {'index': 0}),
            returnsNormally, reason: '${app.projectName}: $name');
      }
      app.modules.values.forEach(check);
    }

    check(config);
  });

  group('LocalStorageProjectFiles', () {
    setUp(() => web.window.localStorage.clear());

    test('seeds sources once, keeps edits, and keeps state on reset',
        () async {
      final defaults = ProjectFiles.decodeSnapshot(seed);
      var files = await LocalStorageProjectFiles.open(seed: defaults);
      expect(files.read('app.yaml'), utf8.decode(defaults['app.yaml']!));

      await files.write('app.yaml', 'edited');
      await files.write('.state/state.yaml', 'state: {}');
      await files.write('.generated/bundle.json', '{}');
      await files.close();

      // Reopened: the edit and the state are there; .generated/ is not.
      files = await LocalStorageProjectFiles.open(seed: defaults);
      expect(files.read('app.yaml'), 'edited');
      expect(files.read('.state/state.yaml'), 'state: {}');
      expect(files.exists('.generated/bundle.json'), isFalse);
      await files.close();

      // Reset: sources back to the defaults, state kept.
      files = await LocalStorageProjectFiles.open(seed: defaults, reset: true);
      expect(files.read('app.yaml'), utf8.decode(defaults['app.yaml']!));
      expect(files.read('.state/state.yaml'), 'state: {}');
      await files.close();
    });

    test('saves each app\'s state next to its sources', () async {
      final files = await LocalStorageProjectFiles.open(
          seed: ProjectFiles.decodeSnapshot(seed));
      final config = (await LiveProject(files, path: projectDir).compile())!;
      final bloc = StateBloc(config: config, store: FilesStateStore(files));
      await bloc.initialize();
      final food = bloc.child('food', config.modules['food']!);
      await Future<void>.delayed(Duration.zero);
      await food.setState({...food.state});

      final storage = web.window.localStorage;
      expect(storage.getItem('${LocalStorageProjectFiles.prefix}.state/state.yaml'),
          startsWith('t:state:'));
      expect(
          storage.getItem(
              '${LocalStorageProjectFiles.prefix}modules/food/.state/state.yaml'),
          startsWith('t:state:'));
      await files.close();
    });
  });
}
