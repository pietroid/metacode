// The UI catalog contract: every widget app/views/ can use and what each
// property means. Pure Dart (no Flutter) so `tool/metacode.dart` validates
// app/views/ against exactly what the renderer implements, and
// `tool/reference.dart` documents it.
//
// Each entry here has a builder in lib/src/widgets/<name>.dart, registered in
// lib/src/registry.dart. test/catalog_test.dart keeps the two in sync.

import 'style.dart';

export 'style.dart';

enum PropKind {
  node('node', 'a page or component, a value, a label, an inline widget, or literal text'),
  nodes('nodes', 'a list of nodes'),
  nodeMap('cases', 'a map of value -> node'),
  action('action', 'name of an action'),
  binding('value', 'name of a value (a function in app/views/values/)'),
  bindingOrLiteral('text', 'a value, a label or a literal'),
  literal('literal', 'a literal (number, text, list, map)'),
  icon('icon', 'an icon name (see Icons)'),
  color('color', 'a color (see Colors)'),
  inline('inline', "another widget's properties, written inline"),
  module('module', 'name of a module (a folder in modules/)');

  final String label;
  final String doc;
  const PropKind(this.label, this.doc);
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
  value('value'),

  /// `module: food`.
  name('name');

  final String? prop;
  const Shorthand(this.prop);
}

class WidgetSpec {
  final String group;
  final String description;
  final Map<String, PropKind> props;
  final Shorthand shorthand;

  /// For [PropKind.inline] props: which catalog widget's properties they take.
  final Map<String, String> inline;

  /// Extra notes on specific props, shown in the reference.
  final Map<String, String> notes;

  const WidgetSpec(
    this.group,
    this.description,
    this.props, {
    this.shorthand = Shorthand.none,
    this.inline = const {},
    this.notes = const {},
  });
}

const _layout = 'Layout';
const _navigation = 'Navigation';
const _content = 'Content';
const _input = 'Input';

const _alignment = {
  'mainAxisAlignment': PropKind.literal,
  'crossAxisAlignment': PropKind.literal,
};

const _alignmentNotes = {
  'mainAxisAlignment': 'start, end, center, spaceBetween, spaceAround, spaceEvenly',
  'crossAxisAlignment': 'start, end, center, stretch',
};

const _box = {
  'padding': PropKind.literal,
  'margin': PropKind.literal,
  'color': PropKind.color,
  'radius': PropKind.literal,
  'width': PropKind.literal,
  'height': PropKind.literal,
};

const _boxNotes = {
  'padding': 'a number (all sides) or {all|horizontal|vertical|left|right|top|bottom}',
  'margin': 'same as padding',
  'radius': 'corner radius',
};

const widgetCatalog = <String, WidgetSpec>{
  // Layout
  'scaffold': WidgetSpec(
    _layout,
    'A page: app bar, body, floating button and bottom navigation.',
    {
      'appBar': PropKind.inline,
      'body': PropKind.node,
      'floatingActionButton': PropKind.node,
      'bottomBar': PropKind.node,
    },
    inline: {'appBar': 'appBar'},
    notes: {'bottomBar': 'usually a navigationBar'},
  ),
  'appBar': WidgetSpec(_layout, 'Top bar of a page.', {
    'title': PropKind.node,
    'actions': PropKind.nodes,
    'backgroundColor': PropKind.color,
  }),
  'column': WidgetSpec(
    _layout,
    'Vertical list of children.',
    {'children': PropKind.nodes, 'spacing': PropKind.literal, ..._alignment},
    shorthand: Shorthand.nodes,
    notes: _alignmentNotes,
  ),
  'row': WidgetSpec(
    _layout,
    'Horizontal list of children.',
    {'children': PropKind.nodes, 'spacing': PropKind.literal, ..._alignment},
    shorthand: Shorthand.nodes,
    notes: _alignmentNotes,
  ),
  'stack': WidgetSpec(
    _layout,
    'Children layered on top of each other.',
    {'children': PropKind.nodes, 'alignment': PropKind.literal},
    shorthand: Shorthand.nodes,
    notes: {
      'alignment': 'topLeft, topCenter, topRight, centerLeft, center, '
          'centerRight, bottomLeft, bottomCenter, bottomRight',
    },
  ),
  'wrap': WidgetSpec(
    _layout,
    'Children that wrap onto new lines.',
    {
      'children': PropKind.nodes,
      'spacing': PropKind.literal,
      'runSpacing': PropKind.literal,
      'alignment': PropKind.literal,
    },
    shorthand: Shorthand.nodes,
    notes: {'alignment': 'start, center, end, spaceBetween, spaceAround, spaceEvenly'},
  ),
  'expanded': WidgetSpec(
    _layout,
    'Fills the remaining space inside a row or column.',
    {'child': PropKind.node, 'flex': PropKind.literal},
    shorthand: Shorthand.node,
  ),
  'spacer': WidgetSpec(
    _layout,
    'Flexible empty space inside a row or column. Write `spacer: {}`.',
    {'flex': PropKind.literal},
  ),
  'center': WidgetSpec(
    _layout,
    'Centers its child.',
    {'child': PropKind.node},
    shorthand: Shorthand.node,
  ),
  'padding': WidgetSpec(
    _layout,
    'Space around a child.',
    {
      'child': PropKind.node,
      'all': PropKind.literal,
      'horizontal': PropKind.literal,
      'vertical': PropKind.literal,
      'left': PropKind.literal,
      'right': PropKind.literal,
      'top': PropKind.literal,
      'bottom': PropKind.literal,
    },
  ),
  'sizedBox': WidgetSpec(_layout, 'Fixed-size box or empty space.', {
    'width': PropKind.literal,
    'height': PropKind.literal,
    'child': PropKind.node,
  }),
  'container': WidgetSpec(
    _layout,
    'A box with padding, margin, background color, border, size and rounded corners.',
    {
      'child': PropKind.node,
      ..._box,
      'borderColor': PropKind.color,
      'maxWidth': PropKind.literal,
    },
    notes: {
      ..._boxNotes,
      'borderColor': 'draws a hairline border (style `sizes.border` wide)',
      'maxWidth': 'fills the width up to this cap, centered when there is more room (page columns on wide screens)',
    },
  ),
  'responsive': WidgetSpec(
    _layout,
    'Shows `wide` when the available width reaches `breakpoint`, else `narrow`. Use it to switch a row of columns to a stack on phones.',
    {'narrow': PropKind.node, 'wide': PropKind.node, 'breakpoint': PropKind.literal},
    notes: {'breakpoint': 'in logical pixels, default 720'},
  ),
  'card': WidgetSpec(
    _layout,
    'A surface with a hairline edge. Tappable with `onTap`.',
    {
      'child': PropKind.node,
      'padding': PropKind.literal,
      'color': PropKind.color,
      'onTap': PropKind.action,
    },
    shorthand: Shorthand.node,
    notes: {'padding': 'inner padding, default spacing.s4 (16)'},
  ),
  'scroll': WidgetSpec(
    _layout,
    'Makes its child scrollable. Do not put `expanded` directly inside.',
    {'child': PropKind.node, 'horizontal': PropKind.literal},
    shorthand: Shorthand.node,
  ),
  'divider': WidgetSpec(_layout, 'A thin line. Write `divider: {}`.', {
    'height': PropKind.literal,
    'color': PropKind.color,
  }),

  'module': WidgetSpec(
    _layout,
    'Embeds a module from `modules/<name>/`: its initial page, with its own '
        'state, actions and values. It inherits the theme unless it has a '
        'style/ folder. Its routes (pages, sheets, dialogs) open over the '
        'whole app, unless `contained: true`: then it gets its own navigator '
        'and they open inside its box (a phone frame), which must have a '
        'bounded size (e.g. inside `expanded`, not `scroll`).',
    {'name': PropKind.module, 'contained': PropKind.literal},
    shorthand: Shorthand.name,
    notes: {'contained': 'true or false (default); `module: food` is short for `module: {name: food}`'},
  ),

  // Navigation
  'match': WidgetSpec(
    _navigation,
    'Shows the case matching a value (e.g. the current page). '
        'Falls back to `default`.',
    {
      'value': PropKind.binding,
      'cases': PropKind.nodeMap,
      'default': PropKind.node,
    },
    notes: {'cases': 'keys are compared to the value as text (enum names work)'},
  ),
  'navigationBar': WidgetSpec(
    _navigation,
    'Bottom navigation. Put it in `scaffold.bottomBar`.',
    {
      'destinations': PropKind.literal,
      'selected': PropKind.binding,
      'onSelected': PropKind.action,
    },
    notes: {
      'destinations': 'list of {icon, label}',
      'selected': 'value returning the selected index (int)',
      'onSelected': 'gets `value` (int): the tapped index',
    },
  ),

  // Content
  'text': WidgetSpec(
    _content,
    'Text.',
    {
      'value': PropKind.bindingOrLiteral,
      'spans': PropKind.literal,
      'style': PropKind.literal,
      'align': PropKind.literal,
      'maxLines': PropKind.literal,
    },
    shorthand: Shorthand.value,
    notes: {
      'spans': 'instead of `value`, runs of text with their own style: a list of strings or {value, style}; each one is a value, a label or literal text, each style overrides `style` (e.g. {color: primary})',
      'style': '{variant (see Text variants), fontSize, fontWeight '
          '(bold, w100..w900), color, italic}',
      'align': 'left, center, right',
    },
  ),
  'icon': WidgetSpec(
    _content,
    'An icon.',
    {'name': PropKind.icon, 'size': PropKind.literal, 'color': PropKind.color},
  ),
  'image': WidgetSpec(
    _content,
    'An image (PNG, JPG, GIF, WebP or SVG) from a URL (http...) or an app file. Put app files in `examples/my_own_app/app/views/style/images/` and use the path: `src: examples/my_own_app/app/views/style/images/logo.svg`.',
    {
      'src': PropKind.bindingOrLiteral,
      'width': PropKind.literal,
      'height': PropKind.literal,
      'fit': PropKind.literal,
      'radius': PropKind.literal,
    },
    shorthand: Shorthand.none,
    notes: {'fit': 'cover, contain, fill, fitWidth, fitHeight'},
  ),
  'avatar': WidgetSpec(
    _content,
    'A round avatar with an image or short text (initials).',
    {
      'text': PropKind.bindingOrLiteral,
      'image': PropKind.bindingOrLiteral,
      'radius': PropKind.literal,
      'color': PropKind.color,
    },
  ),
  'marquee': WidgetSpec(
    _content,
    'A row of children that scrolls sideways in a loop, like a news ticker. Still (and scrollable) when the device asks for reduced motion.',
    {'children': PropKind.nodes, 'spacing': PropKind.literal, 'speed': PropKind.literal},
    shorthand: Shorthand.nodes,
    notes: {'spacing': 'gap between children, default 24', 'speed': 'pixels per second, default 30'},
  ),
  'progress': WidgetSpec(
    _content,
    'Progress indicator. Without `value` it spins forever.',
    {'value': PropKind.bindingOrLiteral, 'circular': PropKind.literal},
    notes: {'value': 'a number from 0 to 1', 'circular': 'true for a circle'},
  ),
  'listView': WidgetSpec(
    _content,
    'A list. `itemBuilder` is built once per item of `data`. Inside `scroll` it moves with the page; on its own (in `expanded`) it scrolls itself.',
    {
      'data': PropKind.binding,
      'itemBuilder': PropKind.node,
      'empty': PropKind.node,
    },
    notes: {
      'data': 'value returning a list',
      'itemBuilder': 'values and actions inside get `index`',
    },
  ),
  'gridView': WidgetSpec(
    _content,
    'A grid. `itemBuilder` is built once per item of `data`. Inside `scroll` it moves with the page; on its own (in `expanded`) it scrolls itself.',
    {
      'data': PropKind.binding,
      'itemBuilder': PropKind.node,
      'empty': PropKind.node,
      'columns': PropKind.literal,
      'spacing': PropKind.literal,
      'aspectRatio': PropKind.literal,
    },
    notes: {
      'columns': 'default 2',
      'aspectRatio': 'item width / height, default 1',
      'itemBuilder': 'values and actions inside get `index`',
    },
  ),
  'listTile': WidgetSpec(_content, 'A list row.', {
    'title': PropKind.node,
    'subtitle': PropKind.node,
    'leading': PropKind.node,
    'trailing': PropKind.node,
    'onTap': PropKind.action,
  }),
  'if': WidgetSpec(_content, 'Shows `then` when the value is true, else `else`.', {
    'condition': PropKind.binding,
    'then': PropKind.node,
    'else': PropKind.node,
  }),

  // Input
  'textField': WidgetSpec(
    _input,
    'Text input.',
    {
      'value': PropKind.bindingOrLiteral,
      'hint': PropKind.bindingOrLiteral,
      'label': PropKind.bindingOrLiteral,
      'multiline': PropKind.literal,
      'onChanged': PropKind.action,
      'onSubmitted': PropKind.action,
    },
    notes: {'onChanged': 'gets `value` (String)', 'onSubmitted': 'gets `value` (String)'},
  ),
  'checkbox': WidgetSpec(
    _input,
    'Checkbox.',
    {'value': PropKind.binding, 'onChanged': PropKind.action},
    notes: {'onChanged': 'gets `value` (bool)'},
  ),
  'toggle': WidgetSpec(
    _input,
    'On/off switch, optionally with a label.',
    {'value': PropKind.binding, 'label': PropKind.node, 'onChanged': PropKind.action},
    notes: {
      'label': 'with a label, the whole row toggles',
      'onChanged': 'gets `value` (bool)',
    },
  ),
  'slider': WidgetSpec(
    _input,
    'Pick a number in a range.',
    {
      'value': PropKind.binding,
      'min': PropKind.literal,
      'max': PropKind.literal,
      'divisions': PropKind.literal,
      'onChanged': PropKind.action,
    },
    notes: {'min': 'default 0', 'max': 'default 1', 'onChanged': 'gets `value` (double)'},
  ),
  'dropdown': WidgetSpec(
    _input,
    'Pick one option from a list.',
    {
      'value': PropKind.binding,
      'options': PropKind.bindingOrLiteral,
      'hint': PropKind.bindingOrLiteral,
      'compact': PropKind.literal,
      'onChanged': PropKind.action,
    },
    notes: {
      'options': 'list of strings, or of {value, text, image} (text: a value, a label or literal text; image: an optional small picture before it, 20x14, e.g. a flag)',
      'compact': 'true: no frame, sized to its text (a small inline picker)',
      'onChanged': 'gets `value` (String)',
    },
  ),
  'choiceChip': WidgetSpec(
    _input,
    'Selectable chip.',
    {'label': PropKind.node, 'selected': PropKind.binding, 'onSelected': PropKind.action},
    notes: {'onSelected': 'gets `value` (bool)'},
  ),
  'iconButton': WidgetSpec(_input, 'Icon that runs an action.', {
    'icon': PropKind.icon,
    'tooltip': PropKind.bindingOrLiteral,
    'color': PropKind.color,
    'onPressed': PropKind.action,
  }),
  'filledButton': WidgetSpec(
    _input,
    'Primary button.',
    {'text': PropKind.node, 'icon': PropKind.icon, 'onPressed': PropKind.action},
  ),
  'outlinedButton': WidgetSpec(
    _input,
    'Secondary button.',
    {'text': PropKind.node, 'icon': PropKind.icon, 'onPressed': PropKind.action},
  ),
  'textButton': WidgetSpec(
    _input,
    'Low-emphasis button.',
    {'text': PropKind.node, 'icon': PropKind.icon, 'onPressed': PropKind.action},
  ),
  'elevatedButton': WidgetSpec(_input, 'Raised button.', {
    'child': PropKind.node,
    'onPressed': PropKind.action,
  }),
  'floatingActionButton': WidgetSpec(_input, 'Floating action button.', {
    'icon': PropKind.icon,
    'child': PropKind.node,
    'onPressed': PropKind.action,
  }),
  'tappable': WidgetSpec(
    _input,
    'Makes any child tappable.',
    {'child': PropKind.node, 'onTap': PropKind.action},
  ),
};

/// Event params an action or value can ask for, by parameter name.
///
/// - `index`: position of the current item inside a `listView`/`gridView`.
/// - `value`: the new value from an input (`textField`, `slider`, ...).
const contextParams = {'index', 'value'};

/// Icon names usable in [PropKind.icon] props. Phosphor icons, mapped in
/// src/icons.dart; their weight comes from app/views/style/ `icons.weight`.
const iconNames = [
  'add', 'remove', 'edit', 'delete', 'close', 'check', 'done', 'clear',
  'search', 'settings', 'home', 'person', 'people', 'favorite',
  'favoriteBorder', 'star', 'starBorder', 'share', 'menu', 'moreVert',
  'moreHoriz', 'arrowBack', 'arrowForward', 'chevronLeft', 'chevronRight',
  'expandMore', 'expandLess', 'refresh', 'info', 'warning', 'error', 'help',
  'notifications', 'email', 'phone', 'calendar', 'schedule', 'alarm',
  'location', 'map', 'camera', 'image', 'photo', 'play', 'pause', 'stop',
  'music', 'shoppingCart', 'payment', 'wallet', 'list', 'grid', 'filter',
  'sort', 'bookmark', 'label', 'flag', 'lock', 'visibility', 'visibilityOff',
  'inbox', 'send', 'chat', 'attach', 'download', 'upload', 'cloud', 'folder',
  'file', 'link', 'logout', 'login', 'lightMode', 'darkMode', 'timer',
  'checkCircle', 'radioUnchecked', 'trendingUp', 'barChart', 'fitness',
  'restaurant', 'local', 'work', 'school', 'pets', 'flight', 'car',
  'trendingDown', 'arrowUp', 'arrowDown', 'arrowUpRight', 'arrowDownLeft',
  'piggyBank', 'target', 'receipt', 'coins', 'chartLine', 'bank', 'gift',
  'sparkle', 'plusCircle', 'user', 'drop', 'book', 'plant', 'pottedPlant',
  'cactus', 'leaf', 'lightbulb', 'palette', 'yoga', 'confetti',
];

/// Color names usable in [PropKind.color] props, besides `#RRGGBB` and
/// `#AARRGGBB`. All follow the app's style (app/views/style/) and light/dark mode.
const colorNames = [
  // Style tokens (see style.dart).
  'bg', 'surface', 'fill', 'fillStrong', 'line', 'lineStrong', 'ink', 'ink2',
  'ink3', 'primary', 'onPrimary', 'accent', 'onAccent', 'success', 'warning',
  'danger', 'info',
  // Material color scheme, derived from the tokens.
  'primaryContainer', 'onPrimaryContainer', 'secondary', 'onSecondary',
  'secondaryContainer', 'onSecondaryContainer', 'tertiary', 'onSurface',
  'onSurfaceVariant', 'outline', 'error',
  // Hues, mapped to the style's tuned colors where one exists.
  'transparent', 'white', 'black', 'grey', 'red', 'green', 'blue', 'orange',
  'amber', 'purple', 'pink', 'teal',
];

/// Text style variants (`text.style.variant`), from the app's theme.
const textVariants = [
  'displayLarge', 'displayMedium', 'displaySmall', 'headlineLarge',
  'headlineMedium', 'headlineSmall', 'titleLarge', 'titleMedium', 'titleSmall',
  'bodyLarge', 'bodyMedium', 'bodySmall', 'labelLarge', 'labelMedium',
  'labelSmall',
];

/// Whether [value] is a valid [PropKind.color].
bool isColor(dynamic value) =>
    value is String &&
    (colorNames.contains(value) || isHexColor(value));

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

/// A component parameter reference: `.screen` (a dot, then a thisCase name).
/// Parameters are not declared: a component's are the ones its widget uses,
/// and every one is required where the component is called:
/// `PhoneFrame: {screen: '#F4FAF5', child: {module: food}}`.
final paramRef = RegExp(r'^\.([a-z][a-zA-Z0-9]*)$');

/// The parameter [value] references (`screen` for `.screen`), else null.
String? paramName(dynamic value) =>
    value is String ? paramRef.firstMatch(value)?.group(1) : null;

/// [node] with every parameter reference replaced by its argument in [args]
/// (as written by the caller). References without an argument are kept.
dynamic substituteParams(dynamic node, Map args) {
  final name = paramName(node);
  if (name != null) return args.containsKey(name) ? args[name] : node;
  if (node is Map) {
    return {
      for (final e in node.entries) e.key: substituteParams(e.value, args),
    };
  }
  if (node is List) return [for (final n in node) substituteParams(n, args)];
  return node;
}
