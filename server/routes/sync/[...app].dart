// GET /sync[/modules/<name>...]: an app's sync stream (a snapshot, then
// deltas); the root's at /sync.
import 'package:dart_frog/dart_frog.dart';
import 'package:metacode/backend/api.dart';

import '../_middleware.dart';

Future<Response> onRequest(RequestContext context, String app) =>
    only(context, HttpMethod.get,
        (backend, user) => apiSync(backend, segments(app), user));
