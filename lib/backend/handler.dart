// The backend's API (api.dart) as a plain shelf handler: what the engine
// tests serve in-process (test/sync_test.dart). The deployed server is the
// Dart Frog project in server/, on the same api.dart.

import 'package:shelf/shelf.dart';

import 'api.dart';
import 'backend.dart';

/// The shelf handler for [backend].
Handler backendHandler(MetacodeBackend backend,
    {Duration ping = const Duration(seconds: 25)}) {
  return (Request request) async {
    if (request.method == 'OPTIONS') {
      return Response.ok(null, headers: corsHeaders);
    }
    final segments = request.url.pathSegments;
    final userId = userIdOf(request.headers);
    final ApiReply reply;
    if (segments.isEmpty) {
      reply = const ApiReply(404, {'error': 'notFound'});
    } else if (userId == null) {
      reply = noUser;
    } else {
      final rest = segments.sublist(1);
      reply = switch ((request.method, segments.first)) {
        ('GET', 'sync') => await apiSync(backend, rest, userId, ping: ping),
        ('POST', 'state') =>
          await apiState(backend, rest, userId, await request.readAsString()),
        ('POST', 'call') =>
          await apiCall(backend, rest, userId, await request.readAsString()),
        _ => const ApiReply(404, {'error': 'notFound'}),
      };
    }
    return Response(reply.status,
        body: reply.events ?? reply.json,
        headers: reply.headers,
        context: {if (reply.events != null) 'shelf.io.buffer_output': false});
  };
}
