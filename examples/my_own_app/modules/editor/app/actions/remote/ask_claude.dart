// askClaude: Sends the prompt (`value`) and the draft to the Claude bridge
// (claudeUrl('claude')), which edits it with the metacode MCP in one
// awaited run. A run that went through sets the draft (when Claude
// succeeded), the reply, cost, time and turns, and adds them to the
// project's (projectCost, projectMs, projectTurns); refuses (bridgeDown) when the bridge can't be reached.
import '../../../.generated/api.dart';
import '../../../.generated/remote_state.dart';
import '../shared/claude_url.dart';

Future<void> askClaude(
    State state, void Function(StateDelta) emit, Api api, String value) async {
  final prompt = value.trim();
  if (prompt.isEmpty) throw RemoteError('emptyPrompt');
  final r = await api.post(claudeUrl('claude'),
      body: {'prompt': prompt, 'project': state.draft.toJson()});
  final json = r.ok ? r.json : null;
  if (json is! Map) throw RemoteError('bridgeDown');
  final c = json['costUsd'];
  final m = json['durationMs'];
  final t = json['turns'];
  final num cost = c is num ? c : 0;
  final num ms = m is num ? m : 0;
  final num turns = t is num ? t : 0;
  final project = json['project'];
  emit(StateDelta(
    draft: json['ok'] == true && project is Map
        ? MetacodeProject.fromJson(Map<String, dynamic>.from(project))
        : state.draft,
    runReply: '${json['reply'] ?? ''}',
    runCost: cost,
    runMs: ms,
    runTurns: turns,
    // toDouble: dart_eval can't add a JSON number to a state number.
    projectCost: state.projectCost.toDouble() + cost.toDouble(),
    projectMs: state.projectMs.toDouble() + ms.toDouble(),
    projectTurns: state.projectTurns.toDouble() + turns.toDouble(),
  ));
}
