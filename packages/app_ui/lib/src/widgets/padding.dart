import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildPadding(Ui ui, Map<String, dynamic> p) =>
    Padding(padding: parsePadding(p), child: ui.node(p['child']));
