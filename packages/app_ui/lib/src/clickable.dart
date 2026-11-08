import 'package:flutter/widgets.dart';

import '../spec.dart';
import 'ui.dart';

/// Widgets people type into: their actions are not clicks.
const _typedInto = {'textField'};

/// Whether the catalog widget [type] with [props] runs an action when
/// clicked: it has an action prop naming a real action (a disabled button
/// is not clickable).
bool isClickable(Ui ui, String type, Map<String, dynamic> props) {
  if (_typedInto.contains(type)) return false;
  final spec = widgetCatalog[type];
  if (spec == null) return false;
  for (final MapEntry(key: name, value: kind) in spec.props.entries) {
    if (kind == PropKind.action && ui.action(props[name]) != null) return true;
  }
  return false;
}

/// Something that runs an action when clicked: a pointer cursor over all of
/// it, and its text out of the app's text selection, so a click (or a drag)
/// on a label clicks instead of selecting.
class Clickable extends StatelessWidget {
  final Widget child;

  const Clickable({super.key, required this.child});

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SelectionContainer.disabled(child: child),
      );
}
