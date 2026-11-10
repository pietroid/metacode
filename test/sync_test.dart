// Scoped state and sync (docs/STATE_ARCHITECTURE.md) on the fixture app
// (test/fixture_app/: voteError is ephemeral, count local, nickname remote,
// voters system, votes shared; `vote` is its remote action): the state
// saved by scope, remote actions without a backend (LocalBackend), and a
// real backend (lib/backend/, served on localhost) with two clients
// (HttpBackend): snapshots, deltas, the outbox, remote calls, offline.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:metacode/backend/backend.dart';
import 'package:metacode/backend/handler.dart';
import 'package:metacode/engine/project_config.dart';
import 'package:metacode/engine/state_bloc.dart';
import 'package:metacode/engine/state_store.dart';
import 'package:metacode/engine/sync/http_backend.dart';
import 'package:metacode/engine/sync/remote_backend.dart';
import 'package:metacode/engine/sync/user_id.dart';
import 'package:metacode/files/project_files.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'engine_test.dart' show compileFixture, fixtureDir, fixtureFiles;

/// Polls [condition] (real time) until it holds.
Future<void> until(bool Function() condition,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late Map<String, dynamic> bundle;
  setUpAll(() => bundle = compileFixture());

  ProjectConfig config() => ProjectConfig.fromBundle(bundle);

  test('the bundle: the client state has no system fields; scopes', () {
    final c = config();
    expect(c.initialState.keys,
        containsAll(['voteError', 'count', 'nickname', 'votes']));
    expect(c.initialState.containsKey('voters'), isFalse);
    expect(c.scopes['voteError'], 'ephemeral');
    expect(c.scopes['votes'], 'shared');
    expect(c.systemSeed, {'voters': []});
    expect(c.remoteFields, containsAll(['nickname', 'votes', 'voters']));
    expect(c.syncs, isTrue);
    expect(c.modules['counter']!.syncs, isFalse);
  });

  test('the state is saved by scope; ephemeral never', () async {
    final files = ProjectFiles();
    final store = FilesStateStore(files);
    final bloc = StateBloc(config: config(), store: store);
    await bloc.initialize();
    await bloc.setState({
      ...bloc.state,
      'voteError': 'x',
      'count': 3,
      'nickname': 'ada',
      'votes': 9,
    });
    expect(files.read('.state/state.yaml'), contains('count: 3'));
    expect(files.read('.state/state.yaml'), isNot(contains('voteError')));
    expect(files.read('.state/state.yaml'), isNot(contains('nickname')));
    expect(files.read('.state/remote.yaml'), contains('nickname: "ada"'));
    expect(files.read('.state/shared.yaml'), contains('votes: 9'));

    final again = StateBloc(config: config(), store: store);
    await again.initialize();
    expect(again.state['voteError'], '');
    expect(again.state['count'], 3);
    expect(again.state['nickname'], 'ada');
    expect(again.state['votes'], 9);
  });

  test('without a backend, remote actions run on the device', () async {
    final files = ProjectFiles();
    final bloc =
        StateBloc(config: config(), store: FilesStateStore(files));
    await bloc.initialize();
    final local = LocalBackend(bloc, bloc.config);

    expect(await local.call('vote', 'ada'), isNull);
    expect(bloc.state['votes'], 1);
    expect(bloc.state['nickname'], 'ada');
    expect(files.read('.state/system.yaml'), contains('"ada"'));
    // Once per name (system `voters`), and refusals change nothing.
    expect(await local.call('vote', 'ada'), isNull);
    expect(await local.call('vote', '  '), 'emptyName');
    expect(await local.call('nope', 'x'), 'unknownAction');
    expect(bloc.state['votes'], 1);
    // The system state survives a relaunch.
    final again = LocalBackend(bloc, bloc.config);
    expect(await again.call('vote', 'ada'), isNull);
    expect(bloc.state['votes'], 1);
  });

  test('the user id is made once and saved', () async {
    final store = FilesStateStore(ProjectFiles());
    final id = await loadUserId(store);
    expect(id, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(await loadUserId(store), id);
  });

  group('with a backend', () {
    late MetacodeBackend backend;
    late HttpServer server;
    late String url;
    late ProjectFiles data;
    final opened = <HttpBackend>[];

    setUp(() async {
      data = ProjectFiles();
      backend = MetacodeBackend(
          code: ProjectFiles.fromSnapshot(fixtureFiles()),
          data: data,
          path: fixtureDir);
      expect(backend.reload(), isTrue, reason: backend.issues.errors.join('\n'));
      server = await shelf_io.serve(
          backendHandler(backend), InternetAddress.loopbackIPv4, 0);
      url = 'http://${server.address.host}:${server.port}';
    });

    tearDown(() async {
      for (final c in opened) {
        c.dispose();
      }
      opened.clear();
      backend.close();
      await server.close(force: true);
    });

    /// A client: its own state (saved in [files]) and user.
    Future<(StateBloc, HttpBackend)> client(String user,
        {ProjectFiles? files, String? at}) async {
      final bloc = StateBloc(
          config: config(), store: FilesStateStore(files ?? ProjectFiles()));
      await bloc.initialize();
      final sync = HttpBackend(
        url: at ?? url,
        bloc: bloc,
        userId: Future.value(user),
        backoff: (_) => const Duration(milliseconds: 50),
      );
      opened.add(sync);
      sync.start();
      return (bloc, sync);
    }

    const ada = 'aaaaaaaa-0000-4000-8000-000000000001';
    const bob = 'bbbbbbbb-0000-4000-8000-000000000002';

    test('a call runs on the backend; shared goes to everyone, remote to '
        'the caller', () async {
      final (adaState, adaSync) = await client(ada);
      final (bobState, bobSync) = await client(bob);
      await adaSync.synced;
      await bobSync.synced;
      // Before their first write, users have no document.
      expect(data.paths.where((p) => p.contains('users/')), isEmpty);

      expect(await adaSync.call('vote', 'Ada'), isNull);
      // Applied before the call completes.
      expect(adaState.state['votes'], 1);
      expect(adaState.state['nickname'], 'ada');
      // Everyone else gets shared over SSE; not Ada's remote fields.
      await until(() => bobState.state['votes'] == 1);
      expect(bobState.state['nickname'], '');
      // Saved: system never sent.
      expect(data.read('.state/system.yaml'), contains('"ada"'));
      expect(data.read('.state/shared.yaml'), contains('votes: 1'));
      expect(data.read('.state/users/$ada.yaml'), contains('"ada"'));

      expect(await bobSync.call('vote', ' '), 'emptyName');
      expect(await bobSync.call('vote', 'ADA'), isNull); // already counted
      expect(bobState.state['votes'], 1);
    });

    test('remote fields: applied at once, sent up, to the user\'s other '
        'devices; a new device gets them in its snapshot', () async {
      final (phone, phoneSync) = await client(ada);
      final (laptop, laptopSync) = await client(ada);
      await phoneSync.synced;
      await laptopSync.synced;

      phone.setState({...phone.state, 'nickname': 'grace'});
      phoneSync.changed({'nickname': 'grace'});
      await until(() => phoneSync.outbox.isEmpty);
      await until(() => laptop.state['nickname'] == 'grace');

      final (tablet, tabletSync) = await client(ada);
      await tabletSync.synced;
      expect(tablet.state['nickname'], 'grace');
    });

    test('offline: the app runs on its cache, calls fail at once, the '
        'outbox waits and is sent on reconnect', () async {
      final files = ProjectFiles();
      // Nothing listens on this port yet.
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;
      await socket.close();
      final (state, sync) =
          await client(ada, files: files, at: 'http://127.0.0.1:$port');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(sync.connected, isFalse);
      expect(await sync.call('vote', 'ada'), 'offline');

      state.setState({...state.state, 'nickname': 'offline'});
      sync.changed({'nickname': 'offline'});
      await until(() => (files.read('.state/outbox.yaml') ?? '').contains('offline'));

      // The backend comes up on that port.
      final late = await shelf_io.serve(
          backendHandler(backend), InternetAddress.loopbackIPv4, port);
      addTearDown(() => late.close(force: true));
      await until(() => sync.connected);
      await until(() => sync.outbox.isEmpty);
      // The snapshot (seed nickname '') never overwrote the pending change.
      expect(state.state['nickname'], 'offline');
      expect(data.read('.state/users/$ada.yaml'), contains('"offline"'));
      expect(jsonDecode(jsonEncode(sync.outbox)), isEmpty);
    });

    test('a client can\'t write shared or unknown fields', () async {
      expect((await backend.pushRemote('', ada, {'votes': 5})).error,
          'invalidFields');
      expect((await backend.pushRemote('', ada, {'nickname': 3})).error,
          'invalidFields');
      expect((await backend.pushRemote('', ada, {'nickname': 'x'})).error,
          isNull);
    });

    test('a hand-edited shared.yaml reaches every client', () async {
      final (state, sync) = await client(bob);
      await sync.synced;
      await data.write('.state/shared.yaml', 'state:\n  votes: 42\n');
      await backend.dataChanged('.state/shared.yaml');
      await until(() => state.state['votes'] == 42);
    });

    test('new code runs without a restart; the data is kept', () async {
      final (state, sync) = await client(ada);
      await sync.synced;
      expect(await sync.call('vote', 'ada'), isNull);
      // A new version of the remote action counts two per vote.
      final source = backend.code.read('app/actions/remote/vote.dart')!;
      await backend.code.write('app/actions/remote/vote.dart',
          source.replaceFirst('state.votes + 1', 'state.votes + 2'));
      expect(backend.reload(), isTrue);
      expect(await sync.call('vote', 'bob'), isNull);
      expect(state.state['votes'], 3);
    });
  });
}
