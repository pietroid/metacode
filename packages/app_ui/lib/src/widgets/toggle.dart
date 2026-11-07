import 'package:flutter/material.dart';

import '../theme.dart';
import '../ui.dart';

Widget buildToggle(Ui ui, Map<String, dynamic> p) {
  final value = ui.binding(p['value']) == true;
  final onChanged = ui.actionWithValue<bool>(p['onChanged']);
  if (p['label'] == null) return MetacodeSwitch(value: value, onChanged: onChanged);
  return _LabeledSwitch(
      value: value, onChanged: onChanged, label: ui.node(p['label']));
}

/// A rounded switch: a 44x26 track with a round thumb that slides across,
/// set in the primary color when on.
class MetacodeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const MetacodeSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = MetacodeTokens.of(context);
    final enabled = onChanged != null;
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: SizedBox(
          width: 52,
          height: 44,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                width: 44,
                height: 26,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: value ? t.primary : t.fillStrong,
                  borderRadius: t.corners('pill'),
                ),
                child: AnimatedAlign(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: value ? t.onPrimary : Colors.white,
                      borderRadius: t.corners('pill'),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width row: label on the left, switch on the right; the whole row
/// toggles.
class _LabeledSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget label;

  const _LabeledSwitch(
      {required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = MetacodeTokens.of(context);
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: t.corners('sm'),
        child: Row(
          children: [
            Expanded(
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodyLarge,
                child: label,
              ),
            ),
            MetacodeSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
