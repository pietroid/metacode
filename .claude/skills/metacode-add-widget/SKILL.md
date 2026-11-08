---
name: metacode-add-widget
description: Add a new widget (or a new property on an existing widget) to the Metacode UI catalog in packages/app_ui so ui/ can use it. Use when the app needs a widget, icon, or prop the catalog lacks.
---

# Add a widget to the catalog

Three edits in `packages/app_ui/lib/`, then the check.

## 1. Spec: `spec.dart`

Add an entry to `widgetCatalog` under its group (`_layout`, `_navigation`, `_content`, `_input`):

```dart
'rating': WidgetSpec(
  _input,
  'Pick 1-5 stars.',
  {'value': PropKind.binding, 'color': PropKind.color, 'onChanged': PropKind.action},
  notes: {'onChanged': 'gets `value` (int): the star tapped'},
),
```

`description` and `notes` end up in REFERENCE.md, which is what app authors read. Always note the `value` type an input passes.

Prop kinds (validated by the tool):
- `node`: one child.
- `nodes`: a list of children.
- `nodeMap`: a map of value to node.
- `action`: names an action.
- `binding`: names a value (a function in `app/views/values/`; the code keeps the old name).
- `bindingOrLiteral`: a value, a label (`app/views/labels/`) or a literal. Read it with `ui.resolve(...)`; use it for every prop that shows text so labels work.
- `literal`: anything.
- `icon`: a name from `iconNames`.
- `color`: `#hex` or a name from `colorNames`.
- `inline`: another widget's props; also set `inline: {'prop': 'widget'}`.

Optional `shorthand`:
- `Shorthand.node`: `x: child`.
- `Shorthand.nodes`: `x: [..]`.
- `Shorthand.value`: `x: "text"`.

## 2. Builder: `src/widgets/<snake_name>.dart`

```dart
import 'package:flutter/material.dart';

import '../parsers.dart';
import '../theme.dart';
import '../ui.dart';

Widget buildRating(Ui ui, Map<String, dynamic> p) {
  final value = (ui.binding(p['value']) as num?)?.toInt() ?? 0;
  final onChanged = ui.actionWithValue<int>(p['onChanged']);
  final color = parseColor(p['color'], ui.context) ?? MetacodeTokens.of(ui.context).accent;
  return Row(mainAxisSize: MainAxisSize.min, children: [
    for (var i = 1; i <= 5; i++)
      IconButton(
        icon: Icon(i <= value ? parseSelectedIcon('star') : parseIcon('starBorder', ui.context), color: color),
        onPressed: onChanged == null ? null : () => onChanged(i),
      ),
  ]);
}
```

`Ui` API (`src/ui.dart`):
- `node(p['child'])`, `nodes(p['children'])`: build children.
- `binding(name)`, `resolve(nameOrLiteral)`: read values.
- `action(name)`, `actionWithValue<T>(name)`: callbacks; these are null when no action is named.
- `withParams({'index': i})`: per-item context.
- `widget(type, props)`: build another catalog widget.

Literal parsers are in `src/parsers.dart`:
- `parseColor(v, ui.context)`
- `parseTextStyle(v, ui.context)`
- `parseIcon(name, ui.context)` (Phosphor, in the style's weight), `parseSelectedIcon(name)` (filled)
- `parseEdgeInsets` (a number or a map)
- `parseAlignment`, `parseBoxFit`, `parseDouble`

Style: never hard-code colors, radii or fonts. Read tokens with `MetacodeTokens.of(ui.context)` (`src/theme.dart`): `t.ink`, `t.color('danger')`, `t.corners('sm')`, `t.spacing['s4']`, `t.displayFamily`, `t.raised` (card shadow). Never use Material `Icons.*`: icons are Phosphor (`src/icons.dart`); a new icon name goes in `iconNames` (spec.dart) and every weight map in `src/icons.dart` (code points from the Phosphor font). Prefer Material widgets whose look comes from the component themes in `MetacodeTheme.build`; if a new Material widget needs a component theme, add it there. Defaults to fallback colors (`?? Colors.amber`) should be tokens too.

New icon, color or text variant names go both in `spec.dart` (`iconNames`, `colorNames`, `textVariants`) and in parsers.dart's maps. If an input passes a value of a new type, add the type to `contextParamTypes` in `tool/src/functions.dart`.

## 3. Register: `src/registry.dart`

Add the import and `'rating': buildRating,` to `widgetBuilders`, under the same group.

## 4. Test: `packages/app_ui/test/widgets_test.dart`

Add a `testWidgets` with `render(tester, {'rating': {...}}, bindings: {...}, actions: {...})`. It returns the recorded action calls. Compare them with `fmt(call)`, e.g. `'rate {value: 3}'`.

## 5. Check

```sh
tool/check_engine.sh
```

This also regenerates `.claude/skills/metacode-app/REFERENCE.md` (widget table) and `reference/widgets/<name>.md`, so app authors see the new widget. `catalog_test.dart` fails if spec, registry, icons or colors disagree. To use the widget in the app, continue with the `metacode-app` skill.
