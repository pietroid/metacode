import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildSlider(Ui ui, Map<String, dynamic> p) {
  final min = parseDouble(p['min']) ?? 0;
  final max = parseDouble(p['max']) ?? 1;
  final value = (ui.binding(p['value']) as num?)?.toDouble() ?? min;
  return Slider(
    value: value.clamp(min, max),
    min: min,
    max: max,
    divisions: p['divisions'] as int?,
    onChanged: ui.actionWithValue<double>(p['onChanged']),
  );
}
