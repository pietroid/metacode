import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildProgress(Ui ui, Map<String, dynamic> p) {
  final value = (ui.resolve(p['value']) as num?)?.toDouble();
  return p['circular'] == true
      ? CircularProgressIndicator(value: value)
      : LinearProgressIndicator(value: value);
}
