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
/// the whole app, unless it is embedded with `contained: true`, which
/// gives it its own navigator (see [embed]). An action's routes go to the
/// navigator it was tapped in ([CoreHost.actionFrom]).
///
/// [reload] swaps in a new version of the app in place; everything
/// [render]ed (the home and pushed routes alike) rebuilds with it.
class AppRuntime extends ChangeNotifier {
  final StateBloc bloc;
  final GlobalKey<NavigatorState> navigatorKey;
  final http.Client? client;

  /// The app-wide language (`core.locale.set`), shared by every module.
  final AppLocale locale;

  /// Whether this is a module (its pages are themed by its style/).
  final bool isModule;

  ProjectConfig _config;
  late UiRenderer _renderer;
  late CoreHost _host;

  final _children = <String, AppRuntime>{};

  AppRuntime({
    required this._config,
    required this.bloc,
    required this.navigatorKey,
    required this.locale,
    this.client,
    this.isModule = false,
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
      onAction: (context) => _host.actionFrom(context),
      readFile: config.readFile,
    );
    config.program.host = _host = CoreHost(
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
  /// only when the values it reads change (or the app is reloaded). A
  /// module's routes opened over the whole app keep the module's style.
  Widget render(String id) => ListenableBuilder(
      listenable: this,
      builder: (context, _) => isModule
          ? _themed(context, _renderer.build(id))
          : _renderer.build(id));

  /// [child] in this app's theme, if it has its own style/. Its `theme:`
  /// (light or dark) wins; `system` follows the embedding app's brightness.
  Widget _themed(BuildContext context, Widget child) => !config.hasOwnStyle
      ? child
      : Theme(
          data: MetacodeTheme.build(
              config.style,
              switch (MetacodeTheme.mode(config.style)) {
                ThemeMode.light => Brightness.light,
                ThemeMode.dark => Brightness.dark,
                ThemeMode.system => Theme.of(context).brightness,
              }),
          child: child,
        );

  /// The initial route's widget.
  Widget get home => ListenableBuilder(
      listenable: this,
      builder: (_, _) => _renderer.build(config.navigation.initialRoute.widget));

  /// The module [name], themed by its own style/ if it has one. When
  /// [contained], it gets its own navigator, so its routes open inside
  /// its box; that box must have a bounded size.
  Widget embed(String name, {bool contained = false}) {
    final child = _child(name);
    if (child == null) {
      return Text('Unknown module "$name"',
          style: const TextStyle(color: Colors.red));
    }
    final home = contained
        ? _ContainedModule(key: ValueKey(name), home: child.home)
        : child.home;
    return ListenableBuilder(
      listenable: child,
      builder: (context, home) => child._themed(context, home!),
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
      isModule: true,
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

/// A module with its own navigator: its pages, sheets and dialogs open
/// inside its box (clipped to it), not over the whole app. The system back
/// button closes them first.
class _ContainedModule extends StatefulWidget {
  final Widget home;
  const _ContainedModule({super.key, required this.home});

  @override
  State<_ContainedModule> createState() => _ContainedModuleState();
}

class _ContainedModuleState extends State<_ContainedModule> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => ClipRect(
        // The box is the module's whole screen: no window insets.
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          removeLeft: true,
          removeRight: true,
          child: HeroControllerScope.none(
            child: NavigatorPopHandler(
              onPopWithResult: (_) => _navigator.currentState?.maybePop(),
              child: Navigator(
                key: _navigator,
                onGenerateInitialRoutes: (_, _) => [
                  // A screen of its own: painted with its theme's bg, not
                  // the embedding app's.
                  MaterialPageRoute<void>(
                      builder: (context) => ColoredBox(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: widget.home,
                          )),
                ],
              ),
            ),
          ),
        ),
      );
}
