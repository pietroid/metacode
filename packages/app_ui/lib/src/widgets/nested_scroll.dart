import 'package:flutter/widgets.dart';

/// Physics for a shrink-wrapped list or grid: inside a vertical scrollable
/// (`scroll`) it doesn't scroll itself, so drags and the mouse wheel over its
/// items move the page instead of an inner list that has nowhere to go.
/// On its own it keeps the platform's scrolling.
ScrollPhysics? nestedPhysics(BuildContext context) {
  final outer = Scrollable.maybeOf(context);
  if (outer != null && outer.axisDirection == AxisDirection.down) {
    return const NeverScrollableScrollPhysics();
  }
  return null;
}
