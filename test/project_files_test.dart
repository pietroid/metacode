// The project's files (lib/files/) and running a project from them
// (lib/engine/live_project.dart): a change to any source compiles a new
// version, wherever the change came from.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:metacode/files/io_project_files.dart';
import 'package:metacode/files/project_files.dart';
import 'package:metacode/engine/live_project.dart';
import 'package:metacode/engine/state_bloc.dart';
import 'package:metacode/engine/state_store.dart';

const projectDir = 'test/fixture_app';

void main() {
  group('ProjectFiles', () {
    final files = ProjectFiles.fromSnapshot({
      'app.yaml': 'name: x',
      'app/actions/a.dart': '',
      'app/actions/sub/b.dart': '',
      'modules/food/app.yaml': '',
      'modules/music/app.yaml': '',
    });

    test('lists files and folders like a file system', () {
      expect(files.list('app/actions'), ['app/actions/a.dart']);
      expect(files.list('app/actions', recursive: true),
          ['app/actions/a.dart', 'app/actions/sub/b.dart']);
      expect(files.list(''), ['app.yaml']);
      expect(files.directories('modules'), ['food', 'music']);
      expect(files.directories(''), ['app', 'modules']);
      expect(files.isDirectory('modules/food'), isTrue);
      expect(files.read('app.yaml'), 'name: x');
    });

    test('reports writes and deletes, not unchanged writes', () async {
      final changes = <Set<String>>[];
      final sub = files.changes.listen(changes.add);
      await files.write('app.yaml', 'name: x');
      await files.write('app.yaml', 'name: y');
      await files.delete('app/actions/a.dart');
      await Future<void>.delayed(Duration.zero);
      expect(changes, [
        {'app.yaml'},
        {'app/actions/a.dart'},
      ]);
      await sub.cancel();
    });

    test('snapshots only text sources', () async {
      await files.write('.generated/bundle.json', '{}');
      expect(files.toSnapshot().keys, isNot(contains('.generated/bundle.json')));
    });
  });

  group('IoProjectFiles', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('metacode_files'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('loads a folder (not hidden files) and writes through', () async {
      File('${tmp.path}/app/a.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync('a: 1');
      File('${tmp.path}/.state/state.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync('state: {}');
      File('${tmp.path}/.generated/x.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
      final files = await IoProjectFiles.open(tmp.path);
      // Sources and state, not .generated/.
      expect(files.paths, ['.state/state.yaml', 'app/a.yaml']);
      await files.write('app/b/c.yaml', 'c: 1');
      expect(File('${tmp.path}/app/b/c.yaml').readAsStringSync(), 'c: 1');
      await files.close();
    });

    test('sees changes made on disk', () async {
      final files = await IoProjectFiles.open(tmp.path, watch: true);
      // Let the watcher start.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final changed = files.changes.first;
      File('${tmp.path}/app.yaml').writeAsStringSync('name: z');
      expect(await changed.timeout(const Duration(seconds: 5)), {'app.yaml'});
      expect(files.read('app.yaml'), 'name: z');
      await files.close();
    }, timeout: const Timeout(Duration(seconds: 15)));
  });

  group('LiveProject', () {
    test('compiles the project from its files, and again on a change',
        () async {
      final files = await _projectInMemory();
      final live = LiveProject(files, path: projectDir);

      final config = (await live.compile())!;
      expect(config.projectName, isNotEmpty);
      await Future<void>.delayed(Duration.zero); // outputs are written after
      expect(files.exists('.generated/bundle.json'), isTrue);

      final next = live.watch(debounce: Duration.zero).first;
      final yaml = files.read('app.yaml')!;
      final name = RegExp(r'^name: .*$', multiLine: true);
      expect(name.hasMatch(yaml), isTrue);
      await files.write('app.yaml', yaml.replaceFirst(name, 'name: Renamed'));
      expect((await next.timeout(const Duration(seconds: 30))).projectName,
          'Renamed');
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('a change during a compile compiles again; the last one wins',
        () async {
      final files = await _projectInMemory();
      final live = LiveProject(files, path: projectDir);
      final yaml = files.read('app.yaml')!;
      final name = RegExp(r'^name: .*$', multiLine: true);
      final next = live.watch(debounce: Duration.zero).first;
      await files.write('app.yaml', yaml.replaceFirst(name, 'name: First'));
      // The first compile is running (it takes far longer than this).
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await files.write('app.yaml', yaml.replaceFirst(name, 'name: Second'));
      expect((await next.timeout(const Duration(seconds: 30))).projectName,
          'Second');
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('serves app files (images) by repo path', () async {
      final live = LiveProject(
          ProjectFiles.fromSnapshot({'app/views/style/images/a.svg': '<svg/>'}),
          path: projectDir);
      expect(live.readFile('$projectDir/app/views/style/images/a.svg'),
          isNotNull);
      expect(live.readFile('elsewhere/a.svg'), isNull);
    });
  });

  group('FilesStateStore', () {
    test('saves each app\'s state next to its sources and reads it back',
        () async {
      final files = await _projectInMemory();
      final config = (await LiveProject(files, path: projectDir).compile())!;
      final store = FilesStateStore(files);

      final bloc = StateBloc(config: config, store: store);
      await bloc.initialize();
      expect(files.read('.state/state.yaml'), startsWith('state:'));

      final module = bloc.child('counter', config.modules['counter']!);
      await Future<void>.delayed(Duration.zero);
      expect(files.read('modules/counter/.state/state.yaml'), startsWith('state:'));

      // A field changed, then a new bloc (the next launch) reads it.
      await module.setState({...module.state, 'taps': 5});
      final again = StateBloc(
          config: config.modules['counter']!, store: store, app: ['counter']);
      await again.initialize();
      expect(again.state['taps'], 5);
    });

    test('reads back nested lists and maps, empty ones included', () async {
      final files = await _projectInMemory();
      final config = (await LiveProject(files, path: projectDir).compile())!;
      final store = FilesStateStore(files);
      final bloc = StateBloc(config: config, store: store);
      await bloc.initialize();
      // A list of models whose fields are lists and models (a recipe with
      // tags and ingredients), and empty lists and maps at every level.
      final nested = {
        'items': [
          {
            'name': 'Salmon, lemon',
            'tags': ['a', 'b'],
            'none': <Object>[],
            'sub': {
              'x': [1, 2],
              'empty': <String, Object>{},
            },
            'parts': [
              {'qty': '10', 'ok': true},
            ],
          },
          <String, Object>{},
        ],
        'grid': [
          [1, 2],
          <Object>[],
        ],
        'empty': <Object>[],
        'emptyMap': <String, Object>{},
      };
      await bloc.setState({...bloc.state, ...nested});
      final again = StateBloc(config: config, store: store);
      await again.initialize();
      for (final key in nested.keys) {
        expect(again.state[key], nested[key], reason: key);
      }
    });
  });
}

/// The real project, in memory: nothing on disk changes.
Future<ProjectFiles> _projectInMemory() async {
  final disk = await IoProjectFiles.open(projectDir);
  return ProjectFiles({
    for (final p in disk.paths)
      if (ProjectFiles.isSource(p)) p: disk.readBytes(p)!,
  });
}
