// resetDraft: Sets the draft to the starter counter, got from the Claude
// bridge (claudeUrl('starter'): the editor's app.yaml draft); refuses
// (bridgeDown) when the bridge can't be reached.
import '../../../.generated/api.dart';
import '../../../.generated/remote_state.dart';
import '../shared/claude_url.dart';

Future<void> resetDraft(
    State state, void Function(StateDelta) emit, Api api) async {
  final r = await api.get(claudeUrl('starter'));
  final json = r.ok ? r.json : null;
  if (json is! Map) throw RemoteError('bridgeDown');
  emit(StateDelta(
      draft: MetacodeProject.fromJson(Map<String, dynamic>.from(json)),
      runReply: ''));
}
