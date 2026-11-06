---
name: metacode-add-widget
description: Add a new widget (or a new property on an existing widget) to the Metacode UI catalog in packages/app_ui so ui.yaml can use it. Use when the app needs a widget, icon, or prop the catalog lacks.
---

# Add a widget to the catalog

Three edits in `packages/app_ui/lib/`, then the check.

## 1. Spec: `spec.dart`

Add an entry to `widgetCatalog`, in the right group (Layout, Content, Input):

```dart
'switchToggle': WidgetSpec('On/off switch; `onChanged` gets `value` (bool).', {
  'value': PropKind.binding,
  'onChanged': PropKind.action,
}),
```

Prop kinds:
- `node`: one child.
- `nodes`: a list of children.
- `action`: names an action.
- `binding`: names a binding.
- `bindingOrLiteral`: a binding name or a literal.
- `literal`: a plain value.
- `inline`: another widget's props; also set `inline: {'prop': 'widget'}`.

Optional `shorthand`:
- `Shorthand.node`: `x: child`.
- `Shorthand.nodes`: `x: [..]`.
- `Shorthand.value`: `x: "text"`.

## 2. Builder: `src/widgets/<snake_name>.dart`

```dart
import 'package:flutter/material.dart';

import '../ui.dart';

Widget buildSwitchToggle(Ui ui, Map<String, dynamic> p) => Switch(
      value: ui.binding(p['value']) == true,
      onChanged: ui.actionWithValue<bool>(p['onChanged']),
    );
```

`Ui` API (`src/ui.dart`):
- `node(p['child'])`, `nodes(p['children'])`: build children.
- `binding(name)`, `resolve(nameOrLiteral)`: read values.
- `action(name)`, `actionWithValue<T>(name)`: callbacks; these are null when no action is named.
- `withParams({'index': i})`: per-item context.
- `widget(type, props)`: build another catalog widget.

Literal parsers (color, text style, icon, padding, alignment) are in `src/parsers.dart`. New icon names go in its `icons` map. If an input passes a value, the action receives it as `value`. Add its type to `_contextParamTypes` in `tool/src/functions.dart` if it's new.

## 3. Register: `src/registry.dart`

Add the import and `'switchToggle': buildSwitchToggle,` to `widgetBuilders`.

## 4. Check

```sh
tool/check_engine.sh
```

`packages/app_ui/test/catalog_test.dart` fails if the spec and the registry disagree. The tool validates ui.yaml against the new spec right away. To use the widget in the app, continue with the `metacode-app` skill.
