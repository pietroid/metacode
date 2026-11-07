import 'package:flutter/material.dart';

import '../style.dart';

/// The resolved design tokens of an app, for one brightness.
///
/// Built from style.yaml (see style.dart) by [MetacodeTheme.build] and stored
/// on the [ThemeData] as an extension, so widget builders read the same
/// tokens the component themes were built from: `MetacodeTokens.of(context)`.
@immutable
class MetacodeTokens extends ThemeExtension<MetacodeTokens> {
  final Brightness brightness;
  final Map<String, Color> colors;
  final Map<String, double> radius;
  final Map<String, double> spacing;
  final Map<String, double> sizes;
  final String? displayFamily;
  final String? textFamily;
  final String iconWeight;

  const MetacodeTokens({
    required this.brightness,
    required this.colors,
    required this.radius,
    required this.spacing,
    required this.sizes,
    required this.displayFamily,
    required this.textFamily,
    required this.iconWeight,
  });

  /// The tokens of the nearest theme, or the Metacode style's when the theme
  /// was not built by [MetacodeTheme] (e.g. a bare MaterialApp in a test).
  static MetacodeTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<MetacodeTokens>() ??
        MetacodeTheme.tokens(resolveStyle(null), theme.brightness);
  }

  bool get dark => brightness == Brightness.dark;

  Color color(String name) => colors[name]!;

  Color get bg => colors['bg']!;
  Color get surface => colors['surface']!;
  Color get fill => colors['fill']!;
  Color get fillStrong => colors['fillStrong']!;
  Color get line => colors['line']!;
  Color get lineStrong => colors['lineStrong']!;
  Color get ink => colors['ink']!;
  Color get ink2 => colors['ink2']!;
  Color get ink3 => colors['ink3']!;
  Color get primary => colors['primary']!;
  Color get onPrimary => colors['onPrimary']!;
  Color get accent => colors['accent']!;

  double get control => sizes['control']!;
  double get icon => sizes['icon']!;
  double get border => sizes['border']!;

  BorderRadius corners(String token) => BorderRadius.circular(radius[token]!);

  /// How a raised surface (a card) separates from the page: a soft two-layer
  /// shadow in light mode; in dark mode shadows vanish, so a hairline edge.
  List<BoxShadow> get raised => dark
      ? const []
      : [
          // A ring instead of a border, a contact shadow, and a soft lift.
          BoxShadow(color: ink.withValues(alpha: 0.05), spreadRadius: 0.5),
          BoxShadow(
            color: ink.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: ink.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];

  /// The edge drawn with [raised]: none in light mode, a hairline in dark.
  BorderSide get raisedEdge =>
      dark ? BorderSide(color: line, width: border) : BorderSide.none;

  /// A floating layer (menus, the floating button): a deeper shadow.
  List<BoxShadow> get floating => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.5 : 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  @override
  MetacodeTokens copyWith() => this;

  @override
  MetacodeTokens lerp(MetacodeTokens? other, double t) {
    if (other == null) return this;
    final self = t < 0.5;
    return MetacodeTokens(
      brightness: self ? brightness : other.brightness,
      colors: {
        for (final k in colors.keys)
          k: Color.lerp(colors[k], other.colors[k], t)!,
      },
      radius: self ? radius : other.radius,
      spacing: self ? spacing : other.spacing,
      sizes: self ? sizes : other.sizes,
      displayFamily: self ? displayFamily : other.displayFamily,
      textFamily: self ? textFamily : other.textFamily,
      iconWeight: self ? iconWeight : other.iconWeight,
    );
  }
}

/// Builds Flutter themes from a resolved style (see [resolveStyle]).
abstract final class MetacodeTheme {
  /// `theme:` in style.yaml as a [ThemeMode].
  static ThemeMode mode(Map<String, dynamic> style) =>
      switch (style['theme']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static MetacodeTokens tokens(Map<String, dynamic> style, Brightness b) {
    final set = (style['colors'] as Map)[b == Brightness.dark ? 'dark' : 'light']
        as Map;
    Map<String, double> numbers(String key) => {
          for (final e in (style[key] as Map).entries)
            e.key as String: (e.value as num).toDouble(),
        };
    final fonts = style['fonts'] as Map;
    return MetacodeTokens(
      brightness: b,
      colors: {
        for (final e in set.entries) e.key as String: _hex(e.value as String),
      },
      radius: numbers('radius'),
      spacing: numbers('spacing'),
      sizes: numbers('sizes'),
      displayFamily: _family(fonts['display']),
      textFamily: _family(fonts['text']),
      iconWeight: (style['icons'] as Map)['weight'] as String,
    );
  }

  /// The full [ThemeData] for [brightness]: color scheme, text theme and a
  /// component theme for every Material widget the catalog uses.
  static ThemeData build(Map<String, dynamic> style, Brightness brightness) {
    final t = tokens(style, brightness);
    final text = _textTheme(style, t);
    final dark = t.dark;
    final c = t.colors;
    final s = t.spacing;

    Color wash(Color color, double alpha) =>
        Color.alphaBlend(color.withValues(alpha: alpha), t.surface);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.primary,
      onPrimary: t.onPrimary,
      primaryContainer: t.fill,
      onPrimaryContainer: t.ink,
      secondary: t.accent,
      onSecondary: c['onAccent']!,
      secondaryContainer: wash(t.accent, dark ? 0.18 : 0.10),
      onSecondaryContainer: t.ink,
      tertiary: c['info']!,
      onTertiary: dark ? t.bg : Colors.white,
      tertiaryContainer: wash(c['info']!, dark ? 0.18 : 0.10),
      onTertiaryContainer: t.ink,
      error: c['danger']!,
      onError: dark ? t.bg : Colors.white,
      errorContainer: wash(c['danger']!, dark ? 0.18 : 0.10),
      onErrorContainer: t.ink,
      surface: t.bg,
      onSurface: t.ink,
      onSurfaceVariant: t.ink2,
      surfaceDim: t.bg,
      surfaceBright: t.surface,
      surfaceContainerLowest: t.surface,
      surfaceContainerLow: t.surface,
      surfaceContainer: t.surface,
      surfaceContainerHigh: t.surface,
      surfaceContainerHighest: t.fill,
      outline: t.lineStrong,
      outlineVariant: t.line,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: t.ink,
      onInverseSurface: t.bg,
      inversePrimary: t.bg,
      surfaceTint: Colors.transparent,
    );

    RoundedRectangleBorder shape(String r, [BorderSide side = BorderSide.none]) =>
        RoundedRectangleBorder(borderRadius: t.corners(r), side: side);
    final controlEdge = BorderSide(color: t.lineStrong, width: t.border);
    final fieldEdge =
        dark ? t.line : Color.lerp(t.line, t.lineStrong, 0.6)!;
    // Pressing darkens (or lightens) quietly; there is no ripple anywhere.
    final press = t.ink.withValues(alpha: dark ? 0.10 : 0.06);
    final hover = t.ink.withValues(alpha: dark ? 0.05 : 0.03);

    ButtonStyle button({
      required Color fg,
      Color? bg,
      BorderSide? side,
      EdgeInsets? padding,
    }) {
      return ButtonStyle(
        textStyle: WidgetStatePropertyAll(text.labelLarge),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled) ? t.ink3 : fg),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (bg == null) return Colors.transparent;
          return states.contains(WidgetState.disabled) ? t.fill : bg;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return fg.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return fg.withValues(alpha: 0.06);
          }
          return null;
        }),
        side: side == null
            ? null
            : WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.disabled)
                    ? side.copyWith(color: t.line)
                    : side),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        minimumSize: WidgetStatePropertyAll(Size(64, t.control)),
        padding: WidgetStatePropertyAll(
            padding ?? EdgeInsets.symmetric(horizontal: s['s5']!)),
        iconSize: const WidgetStatePropertyAll(18),
        shape: WidgetStatePropertyAll(shape('sm')),
        splashFactory: NoSplash.splashFactory,
        animationDuration: const Duration(milliseconds: 120),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      fontFamily: t.textFamily,
      extensions: [t],
      scaffoldBackgroundColor: t.bg,
      canvasColor: t.surface,
      dividerColor: t.line,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: press,
      hoverColor: hover,
      focusColor: hover,
      visualDensity: VisualDensity.standard,
      iconTheme: IconThemeData(color: t.ink2, size: t.icon),
      appBarTheme: AppBarTheme(
        backgroundColor: t.bg,
        foregroundColor: t.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: s['s5'],
        toolbarHeight: 64,
        titleTextStyle: text.headlineMedium,
        iconTheme: IconThemeData(color: t.ink, size: t.icon),
        actionsIconTheme: IconThemeData(color: t.ink, size: t.icon),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: Colors.transparent,
        indicatorShape: shape('sm'),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            text.labelSmall!.copyWith(
                color: states.contains(WidgetState.selected) ? t.ink : t.ink3)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? t.ink : t.ink3)),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape('md', t.raisedEdge),
      ),
      dividerTheme: DividerThemeData(color: t.line, thickness: t.border),
      filledButtonTheme: FilledButtonThemeData(
          style: button(fg: t.onPrimary, bg: t.primary)),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: button(fg: t.ink, bg: t.fill)),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: button(fg: t.ink, side: controlEdge)),
      textButtonTheme: TextButtonThemeData(
          style: button(
              fg: t.ink, padding: EdgeInsets.symmetric(horizontal: s['s3']!))),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled) ? t.ink3 : t.ink2),
          overlayColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.pressed)
                  ? press
                  : states.contains(WidgetState.hovered)
                      ? hover
                      : null),
          iconSize: const WidgetStatePropertyAll(20),
          minimumSize: const WidgetStatePropertyAll(Size.square(40)),
          shape: WidgetStatePropertyAll(shape('pill')),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.primary,
        foregroundColor: t.onPrimary,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 4,
        highlightElevation: 2,
        splashColor: Colors.transparent,
        shape: shape('lg'),
        iconSize: 24,
        extendedTextStyle: text.labelLarge,
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? t.primary : t.fill),
        // Chips resolve only the label color by state.
        labelStyle: text.labelMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? t.onPrimary
                    : states.contains(WidgetState.disabled)
                        ? t.ink3
                        : t.ink2)),
        side: BorderSide.none,
        shape: shape('pill'),
        showCheckmark: false,
        padding: EdgeInsets.symmetric(horizontal: s['s2']!, vertical: 8),
        labelPadding: EdgeInsets.symmetric(horizontal: s['s1']!),
        elevation: 0,
        pressElevation: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: shape('xs'),
        side: WidgetStateBorderSide.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? BorderSide(color: t.primary, width: 1.5)
                : BorderSide(color: t.lineStrong, width: 1.5)),
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? t.primary
                : Colors.transparent),
        checkColor: WidgetStatePropertyAll(t.onPrimary),
        overlayColor: WidgetStatePropertyAll(press),
        splashRadius: 18,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: t.primary,
        inactiveTrackColor: t.fillStrong,
        thumbColor: dark ? t.ink : t.surface,
        overlayColor: Colors.transparent,
        thumbShape: _SoftThumbShape(edge: t.lineStrong),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackShape: const RoundedRectSliderTrackShape(),
        activeTickMarkColor: t.onPrimary.withValues(alpha: 0.5),
        inactiveTickMarkColor: t.lineStrong,
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 1.5),
        valueIndicatorColor: t.ink,
        valueIndicatorTextStyle: text.labelMedium!.copyWith(color: t.bg),
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accent,
        linearTrackColor: t.fill,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 6,
        borderRadius: BorderRadius.circular(3),
        strokeWidth: 3,
        strokeCap: StrokeCap.round,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // White with a soft edge in light mode (reads on a card and on the
        // page alike); a quiet fill in dark mode.
        fillColor: dark ? t.fill : t.surface,
        hoverColor: Colors.transparent,
        isDense: true,
        contentPadding:
            EdgeInsets.symmetric(horizontal: s['s4']!, vertical: 13),
        hintStyle: text.bodyLarge!.copyWith(color: t.ink3),
        labelStyle: text.labelMedium!.copyWith(color: t.ink2),
        floatingLabelStyle: text.labelMedium!.copyWith(color: t.ink2),
        errorStyle: text.labelSmall!.copyWith(color: c['danger']),
        border: _field(t, fieldEdge),
        enabledBorder: _field(t, fieldEdge),
        disabledBorder: _field(t, t.line),
        focusedBorder: _field(t, t.ink, 1.5),
        errorBorder: _field(t, c['danger']!),
        focusedErrorBorder: _field(t, c['danger']!, 1.5),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.accent,
        selectionColor: t.accent.withValues(alpha: 0.22),
        selectionHandleColor: t.accent,
      ),
      listTileTheme: ListTileThemeData(
        // Flush with the content around it (a card's padding, a list's
        // gutter), so tiles align with headings above them.
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 22,
        horizontalTitleGap: s['s3'],
        minVerticalPadding: 12,
        iconColor: t.ink2,
        textColor: t.ink,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
        leadingAndTrailingTextStyle: text.bodyMedium!.copyWith(color: t.ink2),
        shape: shape('sm'),
        visualDensity: VisualDensity.compact,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.bodyLarge,
        menuStyle: _menu(t),
      ),
      menuTheme: MenuThemeData(style: _menu(t)),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: dark ? 0.6 : 0.25),
        shape: shape('md', t.raisedEdge),
        textStyle: text.bodyLarge,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: t.ink, borderRadius: t.corners('xs')),
        textStyle: text.labelSmall!.copyWith(color: t.bg),
        padding: EdgeInsets.symmetric(horizontal: s['s2']!, vertical: 6),
        waitDuration: const Duration(milliseconds: 500),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.ink,
        contentTextStyle: text.bodyMedium!.copyWith(color: t.bg),
        actionTextColor: t.bg,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: shape('sm'),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: shape('lg', t.raisedEdge),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium!.copyWith(color: t.ink2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(t.radius['lg']!))),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(2),
        thumbColor: WidgetStatePropertyAll(t.lineStrong),
      ),
    );
  }

  static TextTheme _textTheme(Map<String, dynamic> style, MetacodeTokens t) {
    final spec = style['typography'] as Map;
    TextStyle variant(String name) {
      final v = spec[name] as Map;
      final size = (v['size'] as num).toDouble();
      return TextStyle(
        fontFamily: v['font'] == 'display' ? t.displayFamily : t.textFamily,
        fontSize: size,
        fontWeight: _weight(v['weight']),
        height: (v['height'] as num).toDouble(),
        letterSpacing: size * (v['tracking'] as num).toDouble(),
        color: name == 'bodySmall' ? t.ink2 : t.ink,
        leadingDistribution: TextLeadingDistribution.even,
      );
    }

    return TextTheme(
      displayLarge: variant('displayLarge'),
      displayMedium: variant('displayMedium'),
      displaySmall: variant('displaySmall'),
      headlineLarge: variant('headlineLarge'),
      headlineMedium: variant('headlineMedium'),
      headlineSmall: variant('headlineSmall'),
      titleLarge: variant('titleLarge'),
      titleMedium: variant('titleMedium'),
      titleSmall: variant('titleSmall'),
      bodyLarge: variant('bodyLarge'),
      bodyMedium: variant('bodyMedium'),
      bodySmall: variant('bodySmall'),
      labelLarge: variant('labelLarge'),
      labelMedium: variant('labelMedium'),
      labelSmall: variant('labelSmall'),
    );
  }

  static OutlineInputBorder _field(MetacodeTokens t, Color color,
          [double? width]) =>
      OutlineInputBorder(
        borderRadius: t.corners('sm'),
        borderSide: BorderSide(color: color, width: width ?? t.border),
      );

  static MenuStyle _menu(MetacodeTokens t) => MenuStyle(
        backgroundColor: WidgetStatePropertyAll(t.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(
            Colors.black.withValues(alpha: t.dark ? 0.6 : 0.25)),
        side: WidgetStatePropertyAll(t.raisedEdge),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: t.corners('md'))),
      );

  static FontWeight _weight(Object? w) => switch (w) {
        500 || 500.0 => FontWeight.w500,
        600 || 600.0 => FontWeight.w600,
        700 || 700.0 => FontWeight.w700,
        _ => FontWeight.w400,
      };

  /// Bundled families are declared in app_ui's pubspec, so outside the
  /// package they are addressed as `packages/app_ui/<family>`.
  static String? _family(Object? family) =>
      family == null || family == 'system' ? null : 'packages/app_ui/$family';

  static Color _hex(String hex) {
    final h = hex.substring(1);
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }
}

/// A round thumb with a soft shadow and a hairline edge, like a physical
/// knob resting on the track.
class _SoftThumbShape extends SliderComponentShape {
  final Color edge;
  const _SoftThumbShape({required this.edge});

  static const _radius = 11.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final radius = _radius + activationAnimation.value;
    canvas.drawCircle(
      center.translate(0, 1.5),
      radius,
      Paint()
        ..color = const Color(0x22000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
        center, radius, Paint()..color = sliderTheme.thumbColor!);
    canvas.drawCircle(
      center,
      radius - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = edge,
    );
  }
}
