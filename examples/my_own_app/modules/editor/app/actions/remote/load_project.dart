// loadProject: Sets the draft to one of the site's example apps (`value`:
// food, travel or work), its source got from the Claude bridge
// (claudeUrl('project?name=')), with no history yet (projectCost,
// projectMs, projectTurns) and no last run; refuses
// (bridgeDown) when the bridge can't be reached, (unknownProject) for
// another name.
import '../../../.generated/api.dart';
import '../../../.generated/remote_state.dart';
import '../shared/claude_url.dart';
import '../shared/project_names.dart';

Future<void> loadProject(
    State state, void Function(StateDelta) emit, Api api, String value) async {
  final names = projectNames();
  if (!names.contains(value)) throw RemoteError('unknownProject');
  final r = await api.get(claudeUrl('project?name=$value'));
  final json = r.ok ? r.json : null;
  if (json is! Map) throw RemoteError('bridgeDown');
  emit(StateDelta(
      draft: MetacodeProject.fromJson(Map<String, dynamic>.from(json)),
      projectName: value,
      runReply: '',
      runCost: 0,
      runMs: 0,
      runTurns: 0,
      projectCost: 0,
      projectMs: 0,
      projectTurns: 0));
}
