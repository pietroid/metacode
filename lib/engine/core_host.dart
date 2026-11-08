import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'host_plugin.dart';
import 'locale.dart';
import 'navigation.dart';
import 'state_bloc.dart';

/// What actions reach through `Core` and `emit`, in the running app.
///
/// - `emit(delta)` merges the delta into the [StateBloc].
/// - `core.api` runs real HTTP requests with [client].
/// - `core.navigator` pushes routing/ routes on the navigator the last
///   action was tapped in (see [actionFrom]): the app's [navigatorKey], or
///   a contained module's own. Pages, bottom sheets and dialogs are all
///   routes, so `pop` closes any of them.
/// - `core.locale.set` picks the language of the whole app ([locale]).
class CoreHost implements MetacodeHost {
  final StateBloc bloc;
  final Navigation navigation;
  final GlobalKey<NavigatorState> navigatorKey;
  final AppLocale locale;
  final http.Client client;

  /// Renders a page (app/views/pages/), kept up to date with the state.
  final Widget Function(String widget) render;

  CoreHost({
    required this.bloc,
    required this.navigation,
    required this.navigatorKey,
    required this.locale,
    required this.render,
    http.Client? client,
  }) : client = client ?? http.Client();

  NavigatorState? _tappedIn;

  /// Called before an action runs: its routes go to the navigator around
  /// [context] (a contained module's, or the app's).
  void actionFrom(BuildContext context) =>
      _tappedIn = Navigator.maybeOf(context);

  NavigatorState? get _navigator {
    final tapped = _tappedIn;
    return tapped != null && tapped.mounted
        ? tapped
        : navigatorKey.currentState;
  }

  @override
  void emit(Map<String, dynamic> delta) =>
      bloc.setState({...bloc.state, ...delta});

  @override
  Future<Object?> call(String op, Map<String, dynamic> args) async {
    switch (op) {
      case 'api':
        return _request(args);
      case 'navigator.push':
        await push(args['route'] as String);
        return null;
      case 'navigator.pop':
        _navigator?.maybePop();
        return null;
      case 'locale.set':
        await locale.set(args['locale'] as String?);
        return null;
    }
    debugPrint('metacode: unknown host operation "$op"');
    return null;
  }

  /// Opens a route and completes when it closes.
  Future<void> push(String name) async {
    final route = navigation.routes[name];
    final navigator = _navigator;
    if (route == null || navigator == null) {
      debugPrint('metacode: cannot push route "$name"');
      return;
    }
    switch (route.type) {
      case RouteType.page:
        await navigator.push(MaterialPageRoute<void>(
          settings: RouteSettings(name: name),
          builder: (_) => render(route.widget),
        ));
      case RouteType.bottomSheet:
        await showModalBottomSheet<void>(
          context: navigator.context,
          routeSettings: RouteSettings(name: name),
          showDragHandle: true,
          builder: (_) => SafeArea(
            child: SingleChildScrollView(child: render(route.widget)),
          ),
        );
      case RouteType.dialog:
        await showDialog<void>(
          context: navigator.context,
          useRootNavigator: false,
          routeSettings: RouteSettings(name: name),
          builder: (_) => Dialog(
            child: SingleChildScrollView(child: render(route.widget)),
          ),
        );
    }
  }

  /// `{method, url, body?, headers?}` -> `{status, body}`. Never throws:
  /// network errors come back as status 0 with the error as body.
  Future<Map<String, Object?>> _request(Map<String, dynamic> args) async {
    try {
      final uri = Uri.parse(args['url'] as String);
      final headers = <String, String>{
        for (final e in ((args['headers'] as Map?) ?? {}).entries)
          e.key.toString(): e.value.toString(),
      };
      final http.Response response;
      if (args['method'] == 'POST') {
        final body = args['body'];
        if (body != null && body is! String) {
          headers.putIfAbsent('content-type', () => 'application/json');
        }
        response = await client.post(uri,
            headers: headers,
            body: body == null || body is String ? body : jsonEncode(body));
      } else {
        response = await client.get(uri, headers: headers);
      }
      return {'status': response.statusCode, 'body': response.body};
    } catch (e) {
      return {'status': 0, 'body': '$e'};
    }
  }
}
