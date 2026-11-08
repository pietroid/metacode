import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core_host.dart';
import 'locale.dart';
import 'project_config.dart';
import 'state_bloc.dart';
import 'ui_renderer.dart';

/// One running app: its state, program, renderer and host. Apps are
/// recursive: an `module: <name>` widget embeds the module `modules/<name>/`,
/// which gets its own [AppRuntime] (created on first use) with its own
/// state, so a change in a module only rebuilds that module.
///
/// All apps share one [navigatorKey]: a module's routes open on top of
/// the whole app.
///
/// [reload] swaps in a new version of the app in place; everything
/// [render]ed (the home and pushed routes alike) rebuilds with it.
class AppRuntime extends ChangeNotifier {
  final StateBloc bloc;
  final GlobalKey<NavigatorState> navigatorKey;
  final http.Client? client;

  /// The app-wide language (`core.locale.set`), shared by every module.
  final AppLocale locale;

  ProjectConfig _config;
  late UiRenderer _renderer;

  final _children = <String, AppRuntime>{};

  AppRuntime({
    required this._config,
    required this.bloc,
    required this.navigatorKey,
    required this.locale,
    this.client,
  }) {
    _start();
  }

  ProjectConfig get config => _config;

  void _start() {
    _renderer = UiRenderer(
      ui: config.ui,
      program: config.program,
      labels: config.labels,
      defaultLanguage: config.defaultLanguage,
      bloc: bloc,
      embed: embed,
      readFile: config.readFile,
    );
    config.program.host = CoreHost(
      bloc: bloc,
      navigation: config.navigation,
      navigatorKey: navigatorKey,
      locale: locale,
      client: client,
      render: render,
    );
  }

  /// Runs [config], a new version of this app (a regenerated or downloaded
  /// bundle), and the new versions of the modules created so far. The state
  /// carries over (see [StateBloc.reconfigure]).
  void reload(ProjectConfig config) {
    _config = config;
    bloc.reconfigure(config);
    _start();
    for (final name in _children.keys.toList()) {
      final childConfig = config.modules[name];
      if (childConfig == null) {
        _children.remove(name)!._close();
      } else {
        _children[name]!.reload(childConfig);
      }
    }
    notifyListeners();
  }

  /// A ui/ widget of this app. Each page and component inside it rebuilds
  /// only when the values it reads change (or the app is reloaded).
  Widget render(String id) =>
      ListenableBuilder(listenable: this, builder: (_, _) => _renderer.build(id));

  /// The initial route's widget.
  Widget get home => ListenableBuilder(
      listenable: this,
      builder: (_, _) => _renderer.build(config.navigation.initialRoute.widget));

  /// The module [name], themed by its own style/ if it has one.
  Widget embed(String name) {
    final child = _child(name);
    if (child == null) {
      return Text('Unknown module "$name"',
          style: const TextStyle(color: Colors.red));
    }
    final home = child.home;
    return ListenableBuilder(
      listenable: child,
      builder: (context, home) => !child.config.hasOwnStyle
          ? home!
          : Theme(
              data: MetacodeTheme.build(
                  child.config.style, Theme.of(context).brightness),
              child: home!,
            ),
      child: home,
    );
  }

  AppRuntime? _child(String name) {
    final existing = _children[name];
    if (existing != null) return existing;
    final config = this.config.modules[name];
    if (config == null) return null;
    return _children[name] = AppRuntime(
      config: config,
      bloc: bloc.child(name, config),
      navigatorKey: navigatorKey,
      locale: locale,
      client: client,
    );
  }

  /// Closes the modules' state (this app's bloc belongs to whoever made it).
  @override
  void dispose() {
    for (final child in _children.values) {
      child._close();
    }
    _children.clear();
    super.dispose();
  }

  void _close() {
    dispose();
    bloc.close();
  }
}
