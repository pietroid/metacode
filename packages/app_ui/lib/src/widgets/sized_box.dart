import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildSizedBox(Ui ui, Map<String, dynamic> p) => SizedBox(
      width: parseDouble(p['width']),
      height: parseDouble(p['height']),
      child: p['child'] == null ? null : ui.node(p['child']),
    );
