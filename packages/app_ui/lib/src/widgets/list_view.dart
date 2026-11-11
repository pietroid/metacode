import 'package:flutter/widgets.dart';

import '../parsers.dart';

import '../ui.dart';
import 'nested_scroll.dart';

Widget buildListView(Ui ui, Map<String, dynamic> p) {
  final items = ui.binding(p['data']);
  if (items is! List || items.isEmpty) return ui.node(p['empty']);
  if (p['horizontal'] == true) {
    // One row, as tall as its tallest item, scrolling sideways.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: parseDouble(p['spacing']) ?? 8,
        children: [
          for (var i = 0; i < items.length; i++)
            ui.withParams({'index': i}).node(p['itemBuilder']),
        ],
      ),
    );
  }
  return Builder(
    // Vertical: no gap unless `spacing` is set (lists of rows draw their own
    // dividers).
    builder: (context) => ListView.separated(
      shrinkWrap: true,
      primary: false,
      physics: nestedPhysics(context),
      itemCount: items.length,
      separatorBuilder: (_, _) =>
          SizedBox(height: parseDouble(p['spacing']) ?? 0),
      itemBuilder: (_, index) =>
          ui.withParams({'index': index}).node(p['itemBuilder']),
    ),
  );
}
