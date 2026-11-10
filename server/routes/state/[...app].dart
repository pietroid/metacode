// POST /state[/modules/<name>...] {fields}: the caller's `remote` fields of
// an app (the root's at /state).
import 'package:dart_frog/dart_frog.dart';
import 'package:metacode/backend/api.dart';

import '../_middleware.dart';

Future<Response> onRequest(RequestContext context, String app) async {
  final body = await context.request.body();
  return only(context, HttpMethod.post,
      (backend, user) => apiState(backend, segments(app), user, body));
}
