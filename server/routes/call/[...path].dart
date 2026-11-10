// POST /call[/modules/<name>...]/<action> {value, locale}: runs a remote
// action; answers its changes for the caller, or {error}.
import 'package:dart_frog/dart_frog.dart';
import 'package:metacode/backend/api.dart';

import '../_middleware.dart';

Future<Response> onRequest(RequestContext context, String path) async {
  final body = await context.request.body();
  return only(context, HttpMethod.post,
      (backend, user) => apiCall(backend, segments(path), user, body));
}
