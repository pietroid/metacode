import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildChoiceChip(Ui ui, Map<String, dynamic> p) => ChoiceChip(
      label: ui.node(p['label']),
      selected: ui.binding(p['selected']) == true,
      onSelected: ui.actionWithValue<bool>(p['onSelected']),
    );
