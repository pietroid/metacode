import 'package:flutter/widgets.dart';

import '../ui.dart';

Widget buildModule(Ui ui, Map<String, dynamic> p) =>
    ui.module('${p['name']}', contained: p['contained'] == true);
