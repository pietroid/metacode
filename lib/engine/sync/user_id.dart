// The anonymous user id (docs/STATE_ARCHITECTURE.md, "Users: anonymous for
// now"): a random UUID made on first launch and saved in
// `.state/user.yaml` (the root app's), sent as the [userHeader] of every
// request. Engine state: never in `State`, so no app code can read it.

import 'dart:math';

import '../state_store.dart';
import '../yaml_writer.dart';

export 'sse.dart' show userHeader;

/// The user id saved in [store] (the root app's `.state/user.yaml`),
/// created on first use. Without a store, a new one each launch.
Future<String> loadUserId(StateStore? store) async {
  final saved =
      readYamlDocument(await store?.read(const [], file: 'user'), 'user');
  final id = saved?['id'];
  if (id is String && id.isNotEmpty) return id;
  final created = newUserId();
  await store?.write(const [], yamlDocument('user', {'id': created}),
      file: 'user');
  return created;
}

/// A random (v4) UUID.
String newUserId() {
  final random = Random.secure();
  final bytes = [for (var i = 0; i < 16; i++) random.nextInt(256)];
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return [
    hex.sublist(0, 4).join(),
    hex.sublist(4, 6).join(),
    hex.sublist(6, 8).join(),
    hex.sublist(8, 10).join(),
    hex.sublist(10).join(),
  ].join('-');
}
