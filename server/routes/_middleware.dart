// Every request: CORS (the web app runs on another origin; preflights end
// here), the anonymous user id checked (it names a file, so only the
// engine's UUIDs pass), and the backend and the id provided to the routes.

import 'package:dart_frog/dart_frog.dart';
import 'package:metacode/backend/api.dart';
import 'package:metacode/backend/backend.dart';

import '../main.dart';

Handler middleware(Handler handler) => (context) async {
      final request = context.request;
      if (request.method == HttpMethod.options) {
        return Response(headers: corsHeaders);
      }
      if (request.uri.pathSegments.where((s) => s.isNotEmpty).isEmpty) {
        return Response.json(body: {'ok': true}, headers: corsHeaders);
      }
      final userId = userIdOf(request.headers);
      if (userId == null) return reply(noUser);
      return handler(context
          .provide<MetacodeBackend>(() => backend)
          .provide<UserId>(() => UserId(userId)));
    };

/// The caller's anonymous id (from the `x-metacode-user` header).
extension type const UserId(String id) {}

/// An [ApiReply] as a Dart Frog response (SSE streamed unbuffered).
Response reply(ApiReply reply) => reply.events != null
    ? Response.stream(
        body: reply.events,
        headers: reply.headers,
        bufferOutput: false,
      )
    : Response(
        statusCode: reply.status,
        body: reply.json,
        headers: reply.headers,
      );

/// `modules/food` -> `[modules, food]`.
List<String> segments(String path) =>
    [for (final s in path.split('/')) if (s.isNotEmpty) s];

/// Answers only [method]; anything else is a 405.
Future<Response> only(
  RequestContext context,
  HttpMethod method,
  Future<ApiReply> Function(MetacodeBackend backend, String userId) run,
) async {
  if (context.request.method != method) {
    return reply(const ApiReply(405, {'error': 'methodNotAllowed'}));
  }
  return reply(
      await run(context.read<MetacodeBackend>(), context.read<UserId>().id));
}
