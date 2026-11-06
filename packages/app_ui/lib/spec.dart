// The UI catalog contract: every widget ui.yaml can use and what each
// property means. Pure Dart (no Flutter) so `tool/metacode.dart` validates
// ui.yaml against exactly what the renderer implements.
//
// Each entry here has a builder in lib/src/widgets/<name>.dart, registered in
// lib/src/registry.dart. test/catalog_test.dart keeps the two in sync.

enum PropKind {
  /// One UI node: a widget id, a binding, an inline widget or literal text.
  node,

  /// A list of UI nodes.
  nodes,

  /// Must name an action.
  action,

  /// Must name a binding.
  binding,

  /// A binding name or a literal value.
  bindingOrLiteral,

  /// A literal value (number, string, color, style map...).
  literal,

  /// The properties of another catalog widget, written inline
  /// (e.g. scaffold's `appBar: {title: ...}`). See [WidgetSpec.inline].
  inline,
}

/// How a widget may be written when its value is not a property map.
/// The shorthand value is moved into [Shorthand.prop] by [normalizeProps].
enum Shorthand {
  none(null),

  /// `expanded: someNode`. A map value is read as properties only when it
  /// has a `child` key.
  node('child'),

  /// `column: [a, b]`.
  nodes('children'),

  /// `text: "Hello"` or `text: someBinding`.
  value('value');

  final String? prop;
  const Shorthand(this.prop);
}

class WidgetSpec {
  final String description;
  final Map<String, PropKind> props;
  final Shorthand shorthand;

  /// For [PropKind.inline] props: which catalog widget's properties they take.
  final Map<String, String> inline;

  const WidgetSpec(
    this.description,
    this.props, {
    this.shorthand = Shorthand.none,
    this.inline = const {},
  });
}

const _alignment = {
  'mainAxisAlignment': PropKind.literal, // start, end, center, spaceBetween, spaceAround, spaceEvenly
  'crossAxisAlignment': PropKind.literal, // start, end, center, stretch
};

const _padding = {
  'all': PropKind.literal,
  'horizontal': PropKind.literal,
  'vertical': PropKind.literal,
  'left': PropKind.literal,
  'right': PropKind.literal,
  'top': PropKind.literal,
  'bottom': PropKind.literal,
};

const widgetCatalog = <String, WidgetSpec>{
  // Layout
  'scaffold': WidgetSpec(
    'A page: optional app bar, body and floating action button.',
    {
      'appBar': PropKind.inline,
      'body': PropKind.node,
      'floatingActionButton': PropKind.node,
    },
    inline: {'appBar': 'appBar'},
  ),
  'appBar': WidgetSpec('Top bar of a page.', {
    'title': PropKind.node,
    'actions': PropKind.nodes,
    'backgroundColor': PropKind.literal,
  }),
  'column': WidgetSpec(
    'Vertical list of children.',
    {'children': PropKind.nodes, ..._alignment},
    shorthand: Shorthand.nodes,
  ),
  'row': WidgetSpec(
    'Horizontal list of children.',
    {'children': PropKind.nodes, ..._alignment},
    shorthand: Shorthand.nodes,
  ),
  'wrap': WidgetSpec(
    'Children that wrap onto new lines.',
    {'children': PropKind.nodes, 'spacing': PropKind.literal},
    shorthand: Shorthand.nodes,
  ),
  'expanded': WidgetSpec(
    'Fills the remaining space inside a row or column.',
    {'child': PropKind.node, 'flex': PropKind.literal},
    shorthand: Shorthand.node,
  ),
  'center': WidgetSpec(
    'Centers its child.',
    {'child': PropKind.node},
    shorthand: Shorthand.node,
  ),
  'padding': WidgetSpec(
    'Space around a child. `all`, or `horizontal`/`vertical`, or each side.',
    {'child': PropKind.node, ..._padding},
  ),
  'sizedBox': WidgetSpec('Fixed-size empty space.', {
    'width': PropKind.literal,
    'height': PropKind.literal,
  }),

  // Content
  'text': WidgetSpec(
    'Text. `style`: {fontSize, fontWeight (bold, w100..w900), color}.',
    {'value': PropKind.bindingOrLiteral, 'style': PropKind.literal},
    shorthand: Shorthand.value,
  ),
  'icon': WidgetSpec('A Material icon by name (see src/parsers.dart).', {
    'name': PropKind.literal,
    'size': PropKind.literal,
    'color': PropKind.literal,
  }),
  'listView': WidgetSpec(
    'Scrollable list. `data` binding returns a list; `itemBuilder` is built '
        'per item with `index` available to bindings and actions.',
    {
      'data': PropKind.binding,
      'itemBuilder': PropKind.node,
      'empty': PropKind.node,
    },
  ),
  'listTile': WidgetSpec('A list row.', {
    'title': PropKind.node,
    'subtitle': PropKind.node,
    'leading': PropKind.node,
    'trailing': PropKind.node,
    'onTap': PropKind.action,
  }),
  'if': WidgetSpec('Shows `then` when the binding is true, else `else`.', {
    'condition': PropKind.binding,
    'then': PropKind.node,
    'else': PropKind.node,
  }),

  // Input
  'textField': WidgetSpec('Text input; `onChanged` gets `value` (String).', {
    'value': PropKind.bindingOrLiteral,
    'hint': PropKind.literal,
    'onChanged': PropKind.action,
  }),
  'checkbox': WidgetSpec('Checkbox; `onChanged` gets `value` (bool).', {
    'value': PropKind.binding,
    'onChanged': PropKind.action,
  }),
  'choiceChip': WidgetSpec('Selectable chip; `onSelected` gets `value` (bool).', {
    'label': PropKind.node,
    'selected': PropKind.binding,
    'onSelected': PropKind.action,
  }),
  'iconButton': WidgetSpec('Icon that runs an action.', {
    'icon': PropKind.literal,
    'tooltip': PropKind.literal,
    'onPressed': PropKind.action,
  }),
  'textButton': WidgetSpec('Flat button.', {
    'text': PropKind.node,
    'onPressed': PropKind.action,
  }),
  'elevatedButton': WidgetSpec('Raised button.', {
    'child': PropKind.node,
    'onPressed': PropKind.action,
  }),
  'floatingActionButton': WidgetSpec('Round floating button.', {
    'child': PropKind.node,
    'onPressed': PropKind.action,
  }),
};

/// Event params an action or binding can ask for, by parameter name.
///
/// - `index`: position of the current item inside a `listView`.
/// - `value`: the new value from an input (`textField`, `checkbox`, ...).
const contextParams = {'index', 'value'};

/// Turns a widget's raw YAML value into its property map, expanding the
/// shorthand form. Returns null when the value is not valid for the widget.
Map<String, dynamic>? normalizeProps(WidgetSpec spec, dynamic value) {
  final prop = spec.shorthand.prop;
  final isPropMap = value is Map &&
      (spec.shorthand != Shorthand.node || value.containsKey('child'));

  if (isPropMap) return Map<String, dynamic>.from(value);
  if (prop == null) return value == null ? const {} : null;
  if (spec.shorthand == Shorthand.nodes && value is! List) return null;
  return {prop: value};
}
