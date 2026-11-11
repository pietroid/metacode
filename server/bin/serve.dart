// The backend without hot reload: what `tool/backend.sh start` runs.
//
// `dart_frog dev` hot-reloads on any .dart change in the server's
// dependencies, and the metacode package it depends on is the whole repo: an
// agent writing an app, `tool/check.sh` regenerating .generated/, or the
// Claude bridge editing a draft restarted the server and dropped every call
// in flight (the client sees `offline`). The backend recompiles the apps on
// its own when their files change, so it doesn't need hot reload; use
// `tool/backend.sh dev` only when changing the backend itself.
//
// The same routes as dart_frog's generated .dart_frog/server.dart: keep them
// in sync when a route is added under routes/.
//
//   cd server && dart run bin/serve.dart        (PORT, default 8080)

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../main.dart' as entrypoint;
import '../routes/_middleware.dart' as middleware;
import '../routes/call/[...path].dart' as call;
import '../routes/state/[...app].dart' as state;
import '../routes/sync/[...app].dart' as sync;

Future<void> main() async {
  final address = InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  await entrypoint.init(address, port);
  final router = Router()
    ..mount('/sync', (context) => sync.onRequest(context, context.request.url.path))
    ..mount('/state', (context) => state.onRequest(context, context.request.url.path))
    ..mount('/call', (context) => call.onRequest(context, context.request.url.path));
  final handler = const Pipeline().addMiddleware(middleware.middleware).addHandler(router);
  await entrypoint.run(handler, address, port);
}
