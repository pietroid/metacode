// navigation.yaml: the routes actions open with `core.navigator.push`.
// Pure Dart: the tool validates with it and the engine renders from it.
//
//   initial: home
//   routes:
//     home: MainPage                        # a page (shorthand)
//     settings: {page: SettingsPage}
//     rate: {bottomSheet: RateSheet}
//     confirmReset: {dialog: ConfirmResetDialog}
//
// Each route shows one page (app/views/pages/). Without navigation.yaml the app
// has a single page, `MainPage`.

enum RouteType { page, bottomSheet, dialog }

class RouteSpec {
  final String name;
  final RouteType type;
  final String widget; // page id (app/views/pages/)

  const RouteSpec(this.name, this.type, this.widget);
}

class Navigation {
  final String initial;
  final Map<String, RouteSpec> routes;

  const Navigation(this.initial, this.routes);

  /// The app without navigation.yaml: one page, `MainPage`.
  static const fallback = Navigation('home', {
    'home': RouteSpec('home', RouteType.page, 'MainPage'),
  });

  RouteSpec get initialRoute => routes[initial]!;

  /// Parses navigation.yaml. Problems go to [error] as (path, message); the
  /// result is null when the document can't be used.
  static Navigation? parse(
    dynamic doc, [
    void Function(String path, String message)? error,
  ]) {
    void fail(String path, String message) => error?.call(path, message);

    if (doc is! Map) {
      fail('', 'must be a map with "initial" and "routes"');
      return null;
    }
    final rawRoutes = doc['routes'];
    if (rawRoutes is! Map || rawRoutes.isEmpty) {
      fail('routes', 'must be a non-empty map of route name -> widget');
      return null;
    }

    final routes = <String, RouteSpec>{};
    for (final entry in rawRoutes.entries) {
      final name = entry.key.toString();
      final path = 'routes.$name';
      if (!RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(name)) {
        fail(path, 'route names are lowerCamelCase identifiers');
        continue;
      }
      final value = entry.value;
      if (value is String) {
        routes[name] = RouteSpec(name, RouteType.page, value);
        continue;
      }
      if (value is Map && value.length == 1) {
        final key = value.keys.first.toString();
        final type = RouteType.values.where((t) => t.name == key).firstOrNull;
        final widget = value.values.first;
        if (type != null && widget is String) {
          routes[name] = RouteSpec(name, type, widget);
          continue;
        }
      }
      fail(path, 'expected a widget id or {page|bottomSheet|dialog: widgetId}');
    }

    final initial = doc['initial'];
    if (initial is! String || !routes.containsKey(initial)) {
      fail('initial', 'must name one of the routes');
      return null;
    }
    if (routes[initial]!.type != RouteType.page) {
      fail('initial', 'the initial route must be a page');
      return null;
    }
    return Navigation(initial, routes);
  }
}
