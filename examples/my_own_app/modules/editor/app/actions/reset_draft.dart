// resetDraft: Puts the draft back to its project's source through the
// remote resetDraft (local actions have no network) and starts it over,
// dropping every edit; askError says why when it fails (askErrorText).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../.generated/api.dart';
import '../../.generated/remote.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/ask_error_text.dart';

Future<void> resetDraft(
    State state, void Function(StateDelta) emit, Remote remote) async {
  emit(StateDelta(askError: ''));
  final error = await remote.resetDraft();
  if (error != null) {
    emit(StateDelta(askError: askErrorText(error.code)));
    return;
  }
  emit(StateDelta(draftOn: false));
  await Future.delayed(const Duration(milliseconds: 120));
  emit(StateDelta(draftOn: true));
}

void main() {
  test('resetDraft without the bridge keeps the draft', () async {
    app.api = (method, url, body) => ApiResponse(status: 0, body: '');
    final state = await app.resetDraft(sample());
    expect(state.draft.toJson(), sample().draft.toJson());
    expect(state.askError, contains('bridge'));
  });

  test('resetDraft puts back the starter from the bridge', () async {
    final starter = {'files': [], 'folders': []};
    app.api = (method, url, body) =>
        ApiResponse(status: 200, body: jsonEncode(starter));
    final state = await app.resetDraft(sample());
    expect(state.draft.toJson(), starter);
    expect(state.draftOn, isTrue);
  });
}
