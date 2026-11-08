// currentCourse: The course open in the course sheet.
import '../../../../.generated/state.dart';

Course currentCourse(State state) => state.courses[state.courseIndex.round()];
