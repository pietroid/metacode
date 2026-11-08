import 'package:flutter/material.dart';

import '../parsers.dart';
import '../theme.dart';
import '../ui.dart';

/// A dropdown framed like a text field, so forms read as one system.
/// `compact` drops the frame: a small inline picker (a language menu in an
/// app bar).
Widget buildDropdown(Ui ui, Map<String, dynamic> p) {
  final t = MetacodeTokens.of(ui.context);
  final text = Theme.of(ui.context).textTheme;
  // An option is a string (shown as is) or {value, text, image} (text: a
  // value, a label or literal text; image: a small picture before it, such
  // as a flag).
  final shown = <String, String>{};
  final images = <String, dynamic>{};
  for (final o in (ui.resolve(p['options']) as List? ?? const [])) {
    if (o is Map) {
      final value = o['value'].toString();
      shown[value] = (ui.resolve(o['text'] ?? value) ?? value).toString();
      if (o['image'] != null) images[value] = o['image'];
    } else {
      shown[o.toString()] = o.toString();
    }
  }
  Widget label(String o) {
    final image = images[o];
    if (image == null) return Text(shown[o]!);
    return Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: ui.widget(
            'image', {'src': image, 'width': 20, 'height': 14, 'fit': 'cover'}),
      ),
      Flexible(child: Text(shown[o]!, overflow: TextOverflow.ellipsis)),
    ]);
  }
  final options = shown.keys.toList();
  final value = ui.binding(p['value'])?.toString();
  final onChanged = ui.actionWithValue<String>(p['onChanged']);
  if (p['compact'] == true) {
    return _CompactDropdown(
      options: options,
      value: options.contains(value) ? value : null,
      label: label,
      onChanged: onChanged,
    );
  }
  final button = DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: options.contains(value) ? value : null,
      hint: p['hint'] == null
          ? null
          : Text(
              ui.resolve(p['hint']).toString(),
              style: text.bodyLarge!.copyWith(color: t.ink3),
            ),
      isExpanded: true,
      isDense: true,
      style: text.bodyLarge,
      icon: Icon(parseIcon('expandMore', ui.context), size: 16, color: t.ink2),
      borderRadius: t.corners('md'),
      dropdownColor: t.surface,
      elevation: 4,
      items: [
        for (final o in options)
          DropdownMenuItem(value: o, child: label(o)),
      ],
      onChanged: onChanged == null
          ? null
          : (v) {
              if (v != null) onChanged(v);
            },
    ),
  );
  return InputDecorator(
    isEmpty: !options.contains(value),
    decoration: const InputDecoration(
      contentPadding: EdgeInsets.fromLTRB(16, 12, 12, 12),
    ),
    child: button,
  );
}

/// The compact picker: the current option and a chevron; the options open
/// in a menu just below it that fades and grows in from the button (a
/// `DropdownButton` menu instead covers the button and unfolds from the
/// selected row, which looks odd in an app bar).
class _CompactDropdown extends StatelessWidget {
  final List<String> options;
  final String? value;
  final Widget Function(String option) label;
  final ValueChanged<String>? onChanged;

  const _CompactDropdown({
    required this.options,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = MetacodeTokens.of(context);
    final text = Theme.of(context).textTheme;
    final current = value;
    return PopupMenuButton<String>(
      enabled: onChanged != null,
      initialValue: current,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      tooltip: '',
      color: t.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: t.corners('md')),
      popUpAnimationStyle: AnimationStyle(
        curve: Curves.easeOutCubic,
        duration: const Duration(milliseconds: 180),
        reverseDuration: const Duration(milliseconds: 120),
      ),
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem(
            value: o,
            height: 40,
            child: DefaultTextStyle.merge(
              style: text.labelLarge!.copyWith(
                  color: o == current ? t.ink : t.ink2),
              child: label(o),
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: DefaultTextStyle.merge(
          style: text.labelLarge,
          child: Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: [
            if (current != null) label(current),
            Icon(parseIcon('expandMore', context), size: 16, color: t.ink2),
          ]),
        ),
      ),
    );
  }
}
