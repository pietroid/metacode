import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

Widget buildIcon(Ui ui, Map<String, dynamic> p) => Icon(
      parseIcon(p['name'], ui.context),
      size: parseDouble(p['size']),
      color: parseColor(p['color'], ui.context),
    );
