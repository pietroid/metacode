// resetDraft: Sets the draft back to its project's source (loadProject's,
// from the Claude bridge: claudeUrl('project?name=')), or to the starter
// counter (claudeUrl('starter'): the editor's app.yaml draft) when no project
// was opened, and clears the project's history (projectCost, projectMs,
// projectTurns) and the last run; refuses (bridgeDown) when the bridge can't be reached.
import '../../../.generated/api.dart';
import '../../../.generated/remote_state.dart';
import '../shared/claude_url.dart';

Future<void> resetDraft(
    State state, void Function(StateDelta) emit, Api api) async {
  var path = 'starter';
  if (state.projectName != '') path = 'project?name=${state.projectName}';
  final r = await api.get(claudeUrl(path));
  final json = r.ok ? r.json : null;
  if (json is! Map) throw RemoteError('bridgeDown');
  emit(StateDelta(
      draft: MetacodeProject.fromJson(Map<String, dynamic>.from(json)),
      runReply: '',
      runCost: 0,
      runMs: 0,
      runTurns: 0,
      projectCost: 0,
      projectMs: 0,
      projectTurns: 0));
}
