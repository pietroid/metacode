// The Metacode backend on Dart Frog (docs/STATE_ARCHITECTURE.md). It
// compiles the app folder (METACODE_CODE, default ../examples/my_own_app)
// as the app does, and again on every change to it, so new code runs
// without a deploy; the state documents live in METACODE_DATA (default
// .backend), apart from the code.
//
//   cd server && flutter pub get && dart run bin/serve.dart   (port 8080; tool/backend.sh)
//   dart_frog dev   (hot reload: restarts on any .dart change in the repo, dropping calls)
//
// The routes (routes/) are thin: the API is lib/backend/api.dart in the
// metacode package, shared with the engine's tests.

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:metacode/backend/backend.dart';
import 'package:metacode/backend/io_backend.dart';

/// The running backend, set by [init] before any request.
late final MetacodeBackend backend;

Future<void> init(InternetAddress ip, int port) async {
  final env = Platform.environment;
  final code = env['METACODE_CODE'] ?? '../examples/my_own_app';
  final data = env['METACODE_DATA'] ?? '.backend';
  final opened = await openBackend(code, data);
  if (opened == null) exit(1);
  backend = opened;
  stdout.writeln('metacode backend: $code (data in $data)');
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) =>
    serve(handler, ip, port);
