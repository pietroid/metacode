import 'package:flutter/widgets.dart';

import '../ui.dart';
import 'nested_scroll.dart';

Widget buildListView(Ui ui, Map<String, dynamic> p) {
  final items = ui.binding(p['data']);
  if (items is! List || items.isEmpty) return ui.node(p['empty']);
  return Builder(
    builder: (context) => ListView.builder(
      shrinkWrap: true,
      primary: false,
      physics: nestedPhysics(context),
      itemCount: items.length,
      itemBuilder: (_, index) =>
          ui.withParams({'index': index}).node(p['itemBuilder']),
    ),
  );
}
