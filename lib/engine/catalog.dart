// The UI catalog: every widget the renderer understands and what each of its
// properties means. Pure Dart (no Flutter) so the `tool/metacode.dart` CLI can
// validate ui.yaml against the exact same contract the renderer implements.

enum PropKind {
  /// A single UI node: a widget id, a binding, an inline widget or literal text.
  node,

  /// A list of UI nodes.
  nodes,

  /// Must name an action.
  action,

  /// Must name a binding.
  binding,

  /// A binding name or a literal value.
  bindingOrLiteral,

  /// A literal value (number, string, color, map of style values...).
  literal,

  /// The properties of an `appBar`, written inline (`appBar: {title: ...}`).
  appBarProps,
}

/// How a widget may be written when its value is not a property map.
enum Shorthand {
  none,

  /// `expanded: someNode` — the value is the child node. A map value is only
  /// read as properties when it contains a `child` key.
  node,

  /// `column: [a, b]` — the value is the children list.
  nodes,

  /// `text: "Hello"` — the value is the text (binding or literal).
  bindingOrLiteral,
}

class WidgetSpec {
  final Map<String, PropKind> props;
  final Shorthand shorthand;

  const WidgetSpec(this.props, {this.shorthand = Shorthand.none});
}

const _alignment = {
  'mainAxisAlignment': PropKind.literal,
  'crossAxisAlignment': PropKind.literal,
};

const widgetCatalog = <String, WidgetSpec>{
  'scaffold': WidgetSpec({
    'appBar': PropKind.appBarProps,
    'body': PropKind.node,
    'floatingActionButton': PropKind.node,
  }),
  'appBar': WidgetSpec({
    'title': PropKind.node,
    'actions': PropKind.nodes,
    'backgroundColor': PropKind.literal,
  }),
  'column': WidgetSpec(
    {'children': PropKind.nodes, ..._alignment},
    shorthand: Shorthand.nodes,
  ),
  'row': WidgetSpec(
    {'children': PropKind.nodes, ..._alignment},
    shorthand: Shorthand.nodes,
  ),
  'wrap': WidgetSpec(
    {'children': PropKind.nodes, 'spacing': PropKind.literal},
    shorthand: Shorthand.nodes,
  ),
  'expanded': WidgetSpec(
    {'child': PropKind.node, 'flex': PropKind.literal},
    shorthand: Shorthand.node,
  ),
  'center': WidgetSpec({'child': PropKind.node}, shorthand: Shorthand.node),
  'padding': WidgetSpec({
    'child': PropKind.node,
    'all': PropKind.literal,
    'horizontal': PropKind.literal,
    'vertical': PropKind.literal,
    'left': PropKind.literal,
    'right': PropKind.literal,
    'top': PropKind.literal,
    'bottom': PropKind.literal,
  }),
  'sizedBox': WidgetSpec({
    'width': PropKind.literal,
    'height': PropKind.literal,
  }),
  'text': WidgetSpec(
    {'value': PropKind.bindingOrLiteral, 'style': PropKind.literal},
    shorthand: Shorthand.bindingOrLiteral,
  ),
  'icon': WidgetSpec({
    'name': PropKind.literal,
    'size': PropKind.literal,
    'color': PropKind.literal,
  }),
  'textField': WidgetSpec({
    'value': PropKind.bindingOrLiteral,
    'hint': PropKind.literal,
    'onChanged': PropKind.action,
  }),
  'iconButton': WidgetSpec({
    'icon': PropKind.literal,
    'tooltip': PropKind.literal,
    'onPressed': PropKind.action,
  }),
  'textButton': WidgetSpec({
    'text': PropKind.node,
    'onPressed': PropKind.action,
  }),
  'elevatedButton': WidgetSpec({
    'child': PropKind.node,
    'onPressed': PropKind.action,
  }),
  'floatingActionButton': WidgetSpec({
    'child': PropKind.node,
    'onPressed': PropKind.action,
  }),
  'listView': WidgetSpec({
    'data': PropKind.binding,
    'itemBuilder': PropKind.node,
    'empty': PropKind.node,
  }),
  'listTile': WidgetSpec({
    'title': PropKind.node,
    'subtitle': PropKind.node,
    'leading': PropKind.node,
    'trailing': PropKind.node,
    'onTap': PropKind.action,
  }),
  'checkbox': WidgetSpec({
    'value': PropKind.binding,
    'onChanged': PropKind.action,
  }),
  'choiceChip': WidgetSpec({
    'label': PropKind.node,
    'selected': PropKind.binding,
    'onSelected': PropKind.action,
  }),
  'if': WidgetSpec({
    'condition': PropKind.binding,
    'then': PropKind.node,
    'else': PropKind.node,
  }),
};

/// Event params an action or binding can ask for, by parameter name.
///
/// - `index`: position of the current item inside a `listView`.
/// - `value`: the new value from an input (`textField`, `checkbox`, ...).
const contextParams = {'index', 'value'};
