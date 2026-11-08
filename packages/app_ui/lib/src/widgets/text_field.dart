import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildTextField(Ui ui, Map<String, dynamic> p) => _TextField(
      value: ui.resolve(p['value'])?.toString() ?? '',
      hint: ui.resolve(p['hint'])?.toString(),
      label: ui.resolve(p['label'])?.toString(),
      multiline: p['multiline'] == true,
      onChanged: ui.actionWithValue<String>(p['onChanged']),
      onSubmitted: ui.actionWithValue<String>(p['onSubmitted']),
    );

/// Keeps a controller so the field follows the state (e.g. cleared after an
/// action) without losing the cursor while typing.
class _TextField extends StatefulWidget {
  final String value;
  final String? hint;
  final String? label;
  final bool multiline;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _TextField({
    required this.value,
    this.hint,
    this.label,
    this.multiline = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_TextField old) {
    super.didUpdateWidget(old);
    if (widget.value != controller.text) controller.text = widget.value;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      minLines: widget.multiline ? 3 : 1,
      maxLines: widget.multiline ? null : 1,
      decoration: InputDecoration(hintText: widget.hint),
    );
    if (widget.label == null) return field;
    // The label sits above the field, set small in the mono face: steadier
    // than a floating label, and it never collides with the value.
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Text(widget.label!,
            style: theme.textTheme.labelMedium!
                .copyWith(color: theme.colorScheme.onSurfaceVariant)),
        field,
      ],
    );
  }
}
