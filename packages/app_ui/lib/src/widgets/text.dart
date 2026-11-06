import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildText(Ui ui, Map<String, dynamic> p) => Text(
      ui.resolve(p['value'])?.toString() ?? '',
      style: parseTextStyle(p['style']),
    );
