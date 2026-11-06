import 'package:flutter/widgets.dart';

import '../ui.dart';

Widget buildSpacer(Ui ui, Map<String, dynamic> p) =>
    Spacer(flex: (p['flex'] as int?) ?? 1);
