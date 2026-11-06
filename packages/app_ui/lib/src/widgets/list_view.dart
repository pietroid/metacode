import 'package:flutter/widgets.dart';

import '../ui.dart';

Widget buildListView(Ui ui, Map<String, dynamic> p) {
  final items = ui.binding(p['data']);
  if (items is! List || items.isEmpty) return ui.node(p['empty']);
  return ListView.builder(
    shrinkWrap: true,
    itemCount: items.length,
    itemBuilder: (_, index) =>
        ui.withParams({'index': index}).node(p['itemBuilder']),
  );
}
