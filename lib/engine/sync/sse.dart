// Server-sent events: the backend's sync stream (`GET /sync/...`). Pure
// Dart; the backend writes [sseEvent], the client reads with [parseSse].

import 'dart:async';
import 'dart:convert';

/// The request header that carries the anonymous user id (user_id.dart).
const userHeader = 'x-metacode-user';

/// One event of the stream: `event: <name>` and its JSON data.
class SseEvent {
  final String name;
  final Map<String, dynamic> data;
  const SseEvent(this.name, this.data);
}

/// [name] and [data] as an SSE event (with the blank line that ends it).
String sseEvent(String name, Map<String, dynamic> data) =>
    'event: $name\ndata: ${jsonEncode(data)}\n\n';

/// The events of an SSE byte stream. Comments (`: ping`) and events whose
/// data isn't a JSON object are skipped.
Stream<SseEvent> parseSse(Stream<List<int>> bytes) async* {
  var name = 'message';
  final data = StringBuffer();
  await for (final line
      in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) {
        try {
          final json = jsonDecode(data.toString());
          if (json is Map) {
            yield SseEvent(name, Map<String, dynamic>.from(json));
          }
        } on FormatException {
          // Not ours: skipped.
        }
      }
      name = 'message';
      data.clear();
    } else if (line.startsWith('event:')) {
      name = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      if (data.isNotEmpty) data.write('\n');
      data.write(line.substring(5).trimLeft());
    }
  }
}
