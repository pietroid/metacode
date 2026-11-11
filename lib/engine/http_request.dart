import 'dart:convert';

import 'package:http/http.dart' as http;

/// Runs a remote action's `api` request (`{method, url, body, headers}`)
/// with [client]: `{status, body}`, status 0 with the error as body when it
/// fails. Never throws.
Future<Map<String, Object?>> httpRequest(
    http.Client client, Map<String, dynamic> args) async {
  try {
    final uri = Uri.parse(args['url'] as String);
    final headers = <String, String>{
      for (final e in ((args['headers'] as Map?) ?? {}).entries)
        e.key.toString(): e.value.toString(),
    };
    final http.Response response;
    if (args['method'] == 'POST') {
      final body = args['body'];
      if (body != null && body is! String) {
        headers.putIfAbsent('content-type', () => 'application/json');
      }
      response = await client.post(uri,
          headers: headers,
          body: body == null || body is String ? body : jsonEncode(body));
    } else {
      response = await client.get(uri, headers: headers);
    }
    return {'status': response.statusCode, 'body': response.body};
  } catch (e) {
    return {'status': 0, 'body': '$e'};
  }
}
