// The title of the example app [name] (food, travel, work), or the
// editor's own title for anything else (the starter counter).
import '../../../../.generated/labels.dart';

String titleOf(Labels labels, String name) {
  if (name == 'food') return labels.foodTitle;
  if (name == 'travel') return labels.travelTitle;
  if (name == 'work') return labels.workTitle;
  return labels.editorTitle;
}
