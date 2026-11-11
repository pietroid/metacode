// askClaude: Asks Claude for the prompt through the remote askClaude (which
// makes the request: local actions have no network), a spinner meanwhile
// (asking); the prompt is cleared when it went through, else askError says
// why (askErrorText). The run's reply and cost are the remote's to write.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../.generated/api.dart';
import '../../.generated/remote.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/ask_error_text.dart';

Future<void> askClaude(
    State state, void Function(StateDelta) emit, Remote remote) async {
  final prompt = state.prompt.trim();
  if (state.asking || prompt.isEmpty) return;
  emit(StateDelta(asking: true, askError: ''));
  final error = await remote.askClaude(prompt);
  if (error == null) {
    emit(StateDelta(asking: false, prompt: ''));
  } else {
    emit(StateDelta(asking: false, askError: askErrorText(error.code)));
  }
}

void main() {
  test('askClaude does nothing without a prompt', () async {
    final state = await app.askClaude(sample());
    expect(app.remoteCalls, isEmpty);
    expect(state.asking, isFalse);
  });

  test('askClaude takes the edited draft, cost and time', () async {
    final edited = {'files': [], 'folders': []};
    app.api = (method, url, body) => ApiResponse(
        status: 200,
        body: jsonEncode({
          'ok': true, 'project': edited, 'reply': 'Done.',
          'costUsd': 0.25, 'durationMs': 30000, 'turns': 5,
        }));
    final typed = await app.setPrompt(sample(), 'make it blue');
    final state = await app.askClaude(typed);
    expect(app.requests, ['POST http://localhost:8787/claude']);
    expect(state.draft.toJson(), edited);
    expect(state.runReply, 'Done.');
    expect(state.totalCost, 0.25);
    expect(state.prompt, '');
    expect(state.asking, isFalse);
  });

  test('askClaude says when the bridge is down', () async {
    app.api = (method, url, body) => ApiResponse(status: 0, body: '');
    final typed = await app.setPrompt(sample(), 'make it blue');
    final state = await app.askClaude(typed);
    expect(state.askError, contains('bridge'));
    expect(state.prompt, 'make it blue');
  });
}
