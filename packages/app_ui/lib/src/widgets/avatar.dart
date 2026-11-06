import 'package:flutter/material.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildAvatar(Ui ui, Map<String, dynamic> p) {
  final image = ui.resolve(p['image'])?.toString();
  final text = ui.resolve(p['text'])?.toString();
  return CircleAvatar(
    radius: parseDouble(p['radius']),
    backgroundColor: parseColor(p['color'], ui.context),
    backgroundImage:
        image != null && image.startsWith('http') ? NetworkImage(image) : null,
    child: text == null ? null : Text(text),
  );
}
