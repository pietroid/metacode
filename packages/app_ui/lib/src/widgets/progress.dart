import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildProgress(Ui ui, Map<String, dynamic> p) {
  final value = (ui.resolve(p['value']) as num?)?.toDouble();
  return Builder(builder: (context) {
    // Without a value it spins forever; when the device asks for reduced
    // motion (and in the layout check) it stands still, like a marquee, at a
    // quarter, so it still reads as "in progress".
    final still = value == null && MediaQuery.of(context).disableAnimations;
    final v = still ? 0.25 : value;
    final color = parseColor(p['color'], context);
    return p['circular'] == true
        ? CircularProgressIndicator(value: v, color: color)
        : LinearProgressIndicator(value: v, color: color);
  });
}
