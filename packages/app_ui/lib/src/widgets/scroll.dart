import 'package:flutter/widgets.dart';

import '../ui.dart';

Widget buildScroll(Ui ui, Map<String, dynamic> p) => SingleChildScrollView(
      scrollDirection:
          p['horizontal'] == true ? Axis.horizontal : Axis.vertical,
      child: ui.node(p['child']),
    );
