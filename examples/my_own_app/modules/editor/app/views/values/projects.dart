// projects: The example apps ProjectPage lists, one ProjectTile each
// (projectNames).
import '../../../.generated/state.dart';
import '../../actions/shared/project_names.dart';

List<String> projects(State state) => projectNames();
