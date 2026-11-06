import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildTextField(Ui ui, Map<String, dynamic> p) =>
    _TextField(ui.resolve(p['value'])?.toString() ?? '', p['hint']?.toString(),
        ui.actionWithValue<String>(p['onChanged']));

/// Keeps a controller so the field follows the state (e.g. cleared after an
/// action) without losing the cursor while typing.
class _TextField extends StatefulWidget {
  final String value;
  final String? hint;
  final ValueChanged<String>? onChanged;

  const _TextField(this.value, this.hint, this.onChanged);

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
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
