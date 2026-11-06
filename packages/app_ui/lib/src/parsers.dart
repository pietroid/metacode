import 'package:flutter/material.dart';

/// Parsers for literal property values shared by widget builders.
/// Allowed names are listed in spec.dart (iconNames, colorNames,
/// textVariants); test/catalog_test.dart keeps both sides in sync.

double? parseDouble(dynamic value) => (value as num?)?.toDouble();

Map<String, Color> themeColors(BuildContext context) {
  final c = Theme.of(context).colorScheme;
  return {
    'primary': c.primary,
    'onPrimary': c.onPrimary,
    'primaryContainer': c.primaryContainer,
    'onPrimaryContainer': c.onPrimaryContainer,
    'secondary': c.secondary,
    'onSecondary': c.onSecondary,
    'secondaryContainer': c.secondaryContainer,
    'onSecondaryContainer': c.onSecondaryContainer,
    'tertiary': c.tertiary,
    'surface': c.surface,
    'onSurface': c.onSurface,
    'onSurfaceVariant': c.onSurfaceVariant,
    'outline': c.outline,
    'error': c.error,
    'transparent': Colors.transparent,
    'white': Colors.white,
    'black': Colors.black,
    'grey': Colors.grey,
    'red': Colors.red,
    'green': Colors.green,
    'blue': Colors.blue,
    'orange': Colors.orange,
    'amber': Colors.amber,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'teal': Colors.teal,
  };
}

Color? parseColor(dynamic value, BuildContext context) {
  if (value is! String) return null;
  if (value.startsWith('#')) {
    final hex = value.substring(1);
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    return null;
  }
  return themeColors(context)[value];
}

FontWeight? parseFontWeight(dynamic value) => const {
      'bold': FontWeight.bold,
      'normal': FontWeight.normal,
      'w100': FontWeight.w100,
      'w200': FontWeight.w200,
      'w300': FontWeight.w300,
      'w400': FontWeight.w400,
      'w500': FontWeight.w500,
      'w600': FontWeight.w600,
      'w700': FontWeight.w700,
      'w800': FontWeight.w800,
      'w900': FontWeight.w900,
    }[value];

Map<String, TextStyle?> textVariantStyles(BuildContext context) {
  final t = Theme.of(context).textTheme;
  return {
    'displayLarge': t.displayLarge,
    'displayMedium': t.displayMedium,
    'displaySmall': t.displaySmall,
    'headlineLarge': t.headlineLarge,
    'headlineMedium': t.headlineMedium,
    'headlineSmall': t.headlineSmall,
    'titleLarge': t.titleLarge,
    'titleMedium': t.titleMedium,
    'titleSmall': t.titleSmall,
    'bodyLarge': t.bodyLarge,
    'bodyMedium': t.bodyMedium,
    'bodySmall': t.bodySmall,
    'labelLarge': t.labelLarge,
    'labelMedium': t.labelMedium,
    'labelSmall': t.labelSmall,
  };
}

TextStyle? parseTextStyle(dynamic style, BuildContext context) {
  if (style is! Map) return null;
  final base = textVariantStyles(context)[style['variant']] ?? const TextStyle();
  return base.copyWith(
    fontSize: parseDouble(style['fontSize']),
    fontWeight: parseFontWeight(style['fontWeight']),
    color: parseColor(style['color'], context),
    fontStyle: style['italic'] == true ? FontStyle.italic : null,
  );
}

TextAlign? parseTextAlign(dynamic value) => const {
      'left': TextAlign.left,
      'center': TextAlign.center,
      'right': TextAlign.right,
    }[value];

const icons = <String, IconData>{
  'add': Icons.add,
  'remove': Icons.remove,
  'edit': Icons.edit,
  'delete': Icons.delete,
  'close': Icons.close,
  'check': Icons.check,
  'done': Icons.done,
  'clear': Icons.clear,
  'search': Icons.search,
  'settings': Icons.settings,
  'home': Icons.home,
  'person': Icons.person,
  'people': Icons.people,
  'favorite': Icons.favorite,
  'favoriteBorder': Icons.favorite_border,
  'star': Icons.star,
  'starBorder': Icons.star_border,
  'share': Icons.share,
  'menu': Icons.menu,
  'moreVert': Icons.more_vert,
  'moreHoriz': Icons.more_horiz,
  'arrowBack': Icons.arrow_back,
  'arrowForward': Icons.arrow_forward,
  'chevronLeft': Icons.chevron_left,
  'chevronRight': Icons.chevron_right,
  'expandMore': Icons.expand_more,
  'expandLess': Icons.expand_less,
  'refresh': Icons.refresh,
  'info': Icons.info_outline,
  'warning': Icons.warning_amber,
  'error': Icons.error_outline,
  'help': Icons.help_outline,
  'notifications': Icons.notifications,
  'email': Icons.email,
  'phone': Icons.phone,
  'calendar': Icons.calendar_today,
  'schedule': Icons.schedule,
  'alarm': Icons.alarm,
  'location': Icons.location_on,
  'map': Icons.map,
  'camera': Icons.camera_alt,
  'image': Icons.image,
  'photo': Icons.photo,
  'play': Icons.play_arrow,
  'pause': Icons.pause,
  'stop': Icons.stop,
  'music': Icons.music_note,
  'shoppingCart': Icons.shopping_cart,
  'payment': Icons.payment,
  'wallet': Icons.account_balance_wallet,
  'list': Icons.list,
  'grid': Icons.grid_view,
  'filter': Icons.filter_list,
  'sort': Icons.sort,
  'bookmark': Icons.bookmark,
  'label': Icons.label,
  'flag': Icons.flag,
  'lock': Icons.lock,
  'visibility': Icons.visibility,
  'visibilityOff': Icons.visibility_off,
  'inbox': Icons.inbox,
  'send': Icons.send,
  'chat': Icons.chat,
  'attach': Icons.attach_file,
  'download': Icons.download,
  'upload': Icons.upload,
  'cloud': Icons.cloud,
  'folder': Icons.folder,
  'file': Icons.insert_drive_file,
  'link': Icons.link,
  'logout': Icons.logout,
  'login': Icons.login,
  'lightMode': Icons.light_mode,
  'darkMode': Icons.dark_mode,
  'timer': Icons.timer,
  'checkCircle': Icons.check_circle,
  'radioUnchecked': Icons.radio_button_unchecked,
  'trendingUp': Icons.trending_up,
  'barChart': Icons.bar_chart,
  'fitness': Icons.fitness_center,
  'restaurant': Icons.restaurant,
  'local': Icons.local_offer,
  'work': Icons.work,
  'school': Icons.school,
  'pets': Icons.pets,
  'flight': Icons.flight,
  'car': Icons.directions_car,
};

IconData parseIcon(dynamic name) => icons[name] ?? Icons.help_outline;

MainAxisAlignment parseMainAxisAlignment(dynamic value) => const {
      'start': MainAxisAlignment.start,
      'end': MainAxisAlignment.end,
      'center': MainAxisAlignment.center,
      'spaceBetween': MainAxisAlignment.spaceBetween,
      'spaceAround': MainAxisAlignment.spaceAround,
      'spaceEvenly': MainAxisAlignment.spaceEvenly,
    }[value] ??
    MainAxisAlignment.start;

CrossAxisAlignment parseCrossAxisAlignment(dynamic value) => const {
      'start': CrossAxisAlignment.start,
      'end': CrossAxisAlignment.end,
      'center': CrossAxisAlignment.center,
      'stretch': CrossAxisAlignment.stretch,
    }[value] ??
    CrossAxisAlignment.center;

Alignment parseAlignment(dynamic value) => const {
      'topLeft': Alignment.topLeft,
      'topCenter': Alignment.topCenter,
      'topRight': Alignment.topRight,
      'centerLeft': Alignment.centerLeft,
      'center': Alignment.center,
      'centerRight': Alignment.centerRight,
      'bottomLeft': Alignment.bottomLeft,
      'bottomCenter': Alignment.bottomCenter,
      'bottomRight': Alignment.bottomRight,
    }[value] ??
    Alignment.topLeft;

BoxFit? parseBoxFit(dynamic value) => const {
      'cover': BoxFit.cover,
      'contain': BoxFit.contain,
      'fill': BoxFit.fill,
      'fitWidth': BoxFit.fitWidth,
      'fitHeight': BoxFit.fitHeight,
    }[value];

/// Padding from a number (all sides) or a map of
/// all/horizontal/vertical/left/right/top/bottom.
EdgeInsets? parseEdgeInsets(dynamic value) {
  if (value == null) return null;
  if (value is num) return EdgeInsets.all(value.toDouble());
  if (value is! Map) return null;
  if (value['all'] != null) return EdgeInsets.all(parseDouble(value['all'])!);
  final h = parseDouble(value['horizontal']);
  final v = parseDouble(value['vertical']);
  return EdgeInsets.only(
    left: parseDouble(value['left']) ?? h ?? 0,
    right: parseDouble(value['right']) ?? h ?? 0,
    top: parseDouble(value['top']) ?? v ?? 0,
    bottom: parseDouble(value['bottom']) ?? v ?? 0,
  );
}
