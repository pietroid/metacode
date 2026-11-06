import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildGridView(Ui ui, Map<String, dynamic> p) {
  final items = ui.binding(p['data']);
  if (items is! List || items.isEmpty) return ui.node(p['empty']);
  final spacing = parseDouble(p['spacing']) ?? 8;
  return GridView.builder(
    shrinkWrap: true,
    itemCount: items.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: (p['columns'] as int?) ?? 2,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: parseDouble(p['aspectRatio']) ?? 1,
    ),
    itemBuilder: (_, index) =>
        ui.withParams({'index': index}).node(p['itemBuilder']),
  );
}
