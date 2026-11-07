import 'package:flutter/widgets.dart';

import '../ui.dart';

Widget buildApp(Ui ui, Map<String, dynamic> p) => ui.app('${p['name']}');
