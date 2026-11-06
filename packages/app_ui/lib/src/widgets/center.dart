import 'package:flutter/widgets.dart';

import '../ui.dart';

Widget buildCenter(Ui ui, Map<String, dynamic> p) =>
    Center(child: ui.node(p['child']));
