// The style contract: the design tokens `metacode/style.yaml` can set, and
// the Metacode style every missing token falls back to. Pure Dart (no
// Flutter) so `tool/metacode.dart` validates style.yaml against exactly what
// `src/theme.dart` reads, and `tool/reference.dart` documents it.
//
// Tokens, not widgets: colors, type, icons, radius, spacing and sizes. Every
// catalog widget is themed from these, so an app restyles without touching
// ui.yaml.

/// Color tokens. Each app has a light and a dark set.
///
/// Color is spent on meaning: [primary] for the one action that matters,
/// [accent] for progress and highlights, and the four states. Everything
/// else is neutral.
const styleColorTokens = <String, String>{
  'bg': 'page background, behind every screen',
  'surface': 'cards, sheets, menus, the navigation bar',
  'fill': 'quiet fill: fields, chips, avatars, containers',
  'fillStrong': 'heavier fill: tracks, pressed states',
  'line': 'hairlines: dividers, card edges in dark mode',
  'lineStrong': 'control borders: outlined buttons, checkboxes',
  'ink': 'primary text and icons',
  'ink2': 'secondary text: labels, captions, subtitles',
  'ink3': 'tertiary text: placeholders, disabled, idle icons',
  'primary': 'the main action fill (filled buttons, checked controls)',
  'onPrimary': 'text and icons on primary',
  'accent': 'progress, the text caret, highlights',
  'onAccent': 'text and icons on accent',
  'success': 'done, positive amounts',
  'warning': 'needs attention',
  'danger': 'destructive, failed, negative amounts',
  'info': 'neutral context',
};

/// Radius tokens.
const styleRadiusTokens = <String, String>{
  'xs': 'checkboxes, tooltips, small indicators',
  'sm': 'buttons, fields',
  'md': 'cards, menus',
  'lg': 'floating buttons, sheets, dialogs',
  'pill': 'switches, chips, avatars, progress bars (999 = fully round)',
};

/// Spacing tokens, on a 4pt grid.
const styleSpacingTokens = <String, String>{
  's1': 'icon to label inside a control',
  's2': 'tightly related elements',
  's3': 'control padding, list row gaps',
  's4': 'default gutter',
  's5': 'card padding',
  's6': 'section gutter',
  's8': 'between sections',
};

/// Size tokens.
const styleSizeTokens = <String, String>{
  'control': 'height of buttons and fields (tap target)',
  'icon': 'default icon size',
  'border': 'hairline and control border width',
};

/// Icon weights (Phosphor). `fill` versions are used for selected states.
const iconWeights = ['thin', 'light', 'regular', 'bold'];

/// Bundled font families, shipped in packages/app_ui/fonts (OFL).
/// Newsreader and Cormorant Garamond are serifs for display text; the
/// others are grotesks for either role. `system` is the platform font.
const fontFamilies = [
  'Albert Sans',
  'Hanken Grotesk',
  'Schibsted Grotesk',
  'Newsreader',
  'Figtree',
  'Plus Jakarta Sans',
  'Cormorant Garamond',
  'system',
];

/// Google Font families downloaded at runtime by the `google_fonts` package.
/// These are never bundled as assets. Use them for custom, editorial looks.
const googleFontFamilies = [
  'Playfair Display',
  'EB Garamond',
  'Libre Baskerville',
  'Lora',
  'Merriweather',
  'Source Sans 3',
  'Inter',
  'Work Sans',
  'Lato',
  'Nunito Sans',
];

/// Every family a style.yaml may reference.
const allFontFamilies = [...fontFamilies, ...googleFontFamilies];

/// The two font roles. Each text variant picks one.
const fontRoles = {
  'display': 'headlines and large titles',
  'text': 'everything read or tapped: body, titles, labels, buttons',
};

/// Keys of one text variant in `typography:`.
const typographyKeys = <String, String>{
  'font': 'display or text',
  'size': 'font size',
  'weight': '400, 500, 600, 700 or 800 (800 only in Plus Jakarta Sans; others use 700)',
  'height': 'line height, as a multiple of size',
  'tracking': 'letter spacing, as a fraction of size (-0.02 = -2%)',
};

/// Theme modes for `theme:`.
const themeModes = ['system', 'light', 'dark'];

/// The Metacode style: classic and quiet. Near-black ink on a soft neutral
/// page, white cards lifted by a whisper of shadow, one deep blue for
/// progress and highlights, Newsreader headlines over Hanken Grotesk text,
/// and Phosphor icons. metacode/style.yaml spells out the same values.
const metacodeStyle = <String, dynamic>{
  'theme': 'system',
  'fonts': {'display': 'Newsreader', 'text': 'Hanken Grotesk'},
  'icons': {'weight': 'regular'},
  'colors': {
    'light': {
      'bg': '#F5F5F3',
      'surface': '#FFFFFF',
      'fill': '#EDEDEA',
      'fillStrong': '#E2E2DE',
      'line': '#E6E6E2',
      'lineStrong': '#CFCFCA',
      'ink': '#151514',
      'ink2': '#62625D',
      'ink3': '#9B9B95',
      'primary': '#151514',
      'onPrimary': '#FFFFFF',
      'accent': '#3049C6',
      'onAccent': '#FFFFFF',
      'success': '#1E7A4C',
      'warning': '#A6600B',
      'danger': '#B93A30',
      'info': '#3B6797',
    },
    'dark': {
      'bg': '#0F0F0E',
      'surface': '#191918',
      'fill': '#232321',
      'fillStrong': '#2E2E2B',
      'line': '#272725',
      'lineStrong': '#3C3C39',
      'ink': '#EDEDEA',
      'ink2': '#A4A49E',
      'ink3': '#6E6E69',
      'primary': '#EDEDEA',
      'onPrimary': '#0F0F0E',
      'accent': '#8C9DF5',
      'onAccent': '#0F0F0E',
      'success': '#4DBA83',
      'warning': '#E2A54E',
      'danger': '#EE7D70',
      'info': '#86ABDB',
    },
  },
  'radius': {'xs': 4, 'sm': 10, 'md': 14, 'lg': 18, 'pill': 999},
  'spacing': {
    's1': 4, 's2': 8, 's3': 12, 's4': 16, 's5': 20, 's6': 24, 's8': 32, //
  },
  'sizes': {'control': 48, 'icon': 22, 'border': 1},
  'typography': {
    'displayLarge': {'font': 'display', 'size': 52, 'weight': 500, 'height': 1.04, 'tracking': -0.016},
    'displayMedium': {'font': 'display', 'size': 44, 'weight': 500, 'height': 1.06, 'tracking': -0.015},
    'displaySmall': {'font': 'display', 'size': 36, 'weight': 500, 'height': 1.1, 'tracking': -0.013},
    'headlineLarge': {'font': 'display', 'size': 30, 'weight': 500, 'height': 1.15, 'tracking': -0.011},
    'headlineMedium': {'font': 'display', 'size': 26, 'weight': 500, 'height': 1.2, 'tracking': -0.009},
    'headlineSmall': {'font': 'display', 'size': 22, 'weight': 500, 'height': 1.25, 'tracking': -0.007},
    'titleLarge': {'font': 'display', 'size': 19, 'weight': 500, 'height': 1.3, 'tracking': -0.005},
    'titleMedium': {'font': 'text', 'size': 17, 'weight': 600, 'height': 1.35, 'tracking': -0.006},
    'titleSmall': {'font': 'text', 'size': 15, 'weight': 600, 'height': 1.4, 'tracking': -0.003},
    'bodyLarge': {'font': 'text', 'size': 16, 'weight': 400, 'height': 1.5, 'tracking': 0},
    'bodyMedium': {'font': 'text', 'size': 15, 'weight': 400, 'height': 1.5, 'tracking': 0},
    'bodySmall': {'font': 'text', 'size': 13, 'weight': 400, 'height': 1.45, 'tracking': 0.004},
    'labelLarge': {'font': 'text', 'size': 15, 'weight': 600, 'height': 1.25, 'tracking': -0.002},
    'labelMedium': {'font': 'text', 'size': 13, 'weight': 500, 'height': 1.3, 'tracking': 0.004},
    'labelSmall': {'font': 'text', 'size': 12, 'weight': 500, 'height': 1.3, 'tracking': 0.01},
  },
};

/// The text variants `typography:` can set (same names as ui.yaml's
/// `text.style.variant`).
List<String> get typographyVariants =>
    (metacodeStyle['typography'] as Map).keys.cast<String>().toList();

/// [style] (a parsed style.yaml, or null) merged over [metacodeStyle].
/// Unknown keys are dropped; numbers become doubles.
Map<String, dynamic> resolveStyle(dynamic style) =>
    _merge(metacodeStyle, style is Map ? style : const {});

Map<String, dynamic> _merge(Map base, Map over) => {
      for (final entry in base.entries)
        entry.key as String: switch ((entry.value, over[entry.key])) {
          (Map b, Map o) => _merge(b, o),
          (Map b, _) => _merge(b, const {}),
          (num _, num o) => o.toDouble(),
          (num b, _) => b.toDouble(),
          (_, String o) => o,
          (final b, _) => b,
        },
    };

/// Problems in a parsed style.yaml, as (path, message). Empty when valid.
List<(String, String)> validateStyle(dynamic style) {
  final issues = <(String, String)>[];
  void error(String path, String message) => issues.add((path, message));

  if (style == null) return issues;
  if (style is! Map) {
    error('', 'expected a map of style sections');
    return issues;
  }

  bool section(String key) {
    final value = style[key];
    if (value == null) return false;
    if (value is Map) return true;
    error(key, 'expected a map');
    return false;
  }

  void keys(Map value, Iterable<String> allowed, String path) {
    for (final key in value.keys) {
      if (!allowed.contains(key)) {
        error(path.isEmpty ? '$key' : '$path.$key',
            'unknown key; available: ${allowed.join(', ')}');
      }
    }
  }

  void numbers(String name, Map<String, String> tokens) {
    if (!section(name)) return;
    final value = style[name] as Map;
    keys(value, tokens.keys, name);
    value.forEach((key, v) {
      if (tokens.containsKey(key) && (v is! num || v < 0)) {
        error('$name.$key', 'expected a number >= 0, got "$v"');
      }
    });
  }

  keys(style, metacodeStyle.keys, '');

  final theme = style['theme'];
  if (theme != null && !themeModes.contains(theme)) {
    error('theme', 'expected one of ${themeModes.join(', ')}, got "$theme"');
  }

  if (section('fonts')) {
    final fonts = style['fonts'] as Map;
    keys(fonts, fontRoles.keys, 'fonts');
      fonts.forEach((role, family) {
        if (fontRoles.containsKey(role) && !allFontFamilies.contains(family)) {
          error('fonts.$role',
              'unknown font "$family"; available: ${allFontFamilies.join(', ')}');
        }
      });
  }

  if (section('icons')) {
    final icons = style['icons'] as Map;
    keys(icons, const ['weight'], 'icons');
    final weight = icons['weight'];
    if (weight != null && !iconWeights.contains(weight)) {
      error('icons.weight',
          'expected one of ${iconWeights.join(', ')}, got "$weight"');
    }
  }

  if (section('colors')) {
    final colors = style['colors'] as Map;
    keys(colors, const ['light', 'dark'], 'colors');
    for (final mode in const ['light', 'dark']) {
      final set = colors[mode];
      if (set == null) continue;
      if (set is! Map) {
        error('colors.$mode', 'expected a map of color tokens');
        continue;
      }
      keys(set, styleColorTokens.keys, 'colors.$mode');
      set.forEach((key, value) {
        if (styleColorTokens.containsKey(key) && !isHexColor(value)) {
          error('colors.$mode.$key', 'expected #RRGGBB or #AARRGGBB, got "$value"');
        }
      });
    }
  }

  numbers('radius', styleRadiusTokens);
  numbers('spacing', styleSpacingTokens);
  numbers('sizes', styleSizeTokens);

  if (section('typography')) {
    final typography = style['typography'] as Map;
    keys(typography, typographyVariants, 'typography');
    typography.forEach((variant, value) {
      if (!typographyVariants.contains(variant)) return;
      final path = 'typography.$variant';
      if (value is! Map) return error(path, 'expected a map');
      keys(value, typographyKeys.keys, path);
      final font = value['font'];
      if (font != null && !fontRoles.containsKey(font)) {
        error('$path.font', 'expected display or text, got "$font"');
      }
      final weight = value['weight'];
      if (weight != null && !const [400, 500, 600, 700, 800].contains(weight)) {
        error('$path.weight', 'expected 400, 500, 600, 700 or 800, got "$weight"');
      }
      for (final key in const ['size', 'height']) {
        final v = value[key];
        if (v != null && (v is! num || v <= 0)) {
          error('$path.$key', 'expected a number > 0, got "$v"');
        }
      }
      final tracking = value['tracking'];
      if (tracking != null && tracking is! num) {
        error('$path.tracking', 'expected a number, got "$tracking"');
      }
    });
  }
  return issues;
}

/// Whether [value] is `#RRGGBB` or `#AARRGGBB`.
bool isHexColor(dynamic value) =>
    value is String &&
    RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(value);
