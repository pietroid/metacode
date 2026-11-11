import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core_host.dart';
import 'dynamic_module.dart';
import 'locale.dart';
import 'project_config.dart';
import 'state_bloc.dart';
import 'sync/http_backend.dart';
import 'sync/remote_backend.dart';
import 'sync/user_id.dart';
import 'ui_renderer.dart';

/// The backend every app of the tree syncs with (docs/STATE_ARCHITECTURE.md),
/// and the anonymous user id they share.
class SyncLink {
  /// The backend's URL.
  final String url;

  /// The user id (`.state/user.yaml`, created on first launch).
  final Future<String> userId;

  const SyncLink(this.url, this.userId);
}

/// One running app: its state, program, renderer and host. Apps are
/// recursive: the module `modules/<name>/` gets its own [AppRuntime]
/// (created on first use) with its own state, so a change in a module only
/// rebuilds that module. Its parent uses it whole (`miniApp: food`, see
/// [embed]) or in parts (`food.MenuCard`, `food.addItem`, `food.total` in
/// app/views/; `core.modules.food` in code), always on its own state.
///
/// All apps share one [navigatorKey]: a module's routes open on top of
/// the whole app, except in a mini app, which has its own navigator. An
/// action's routes go to the navigator it was tapped in
/// ([CoreHost.actionFrom]).
///
/// A [sandboxed] app (a dynamic module, see dynamic_module.dart) has no
/// backend link: nothing reaches past it.
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
    this.runStart = true,
    this.sandboxed = false,
    SyncLink? link,
  }) {
    _link = sandboxed ? null : link ?? _rootLink();
    _startRemote();
    _start();
    _runStartAction();
  }

  /// `--dart-define=METACODE_BACKEND=<url>` overrides app.yaml's `backend:`
  /// (local development); `none` runs without one.
  static const _backendOverride = String.fromEnvironment('METACODE_BACKEND');

  /// The backend, shared with the modules; null runs every app's remote
  /// actions on the device ([LocalBackend]).
  late final SyncLink? _link;

  SyncLink? _rootLink() {
    final url =
        _backendOverride.isNotEmpty ? _backendOverride : _config.backend;
    if (url == null || url.isEmpty || url == 'none') return null;
    return SyncLink(url, loadUserId(bloc.store));
  }

  /// This app's [RemoteBackend], when it has `remote` or `shared` state or
  /// remote actions.
  RemoteBackend? _remote;

  void _startRemote() {
    if (_remote != null) return _remote!.reconfigure(_config);
    if (!_config.syncs) return;
    final link = _link;
    _remote = link == null
        ? LocalBackend(bloc, _config, client: client)
        : HttpBackend(
            url: link.url,
            bloc: bloc,
            userId: link.userId,
            app: bloc.app,
            client: client);
    _remote!.start();
  }

  /// Whether this app runs apart from any other: a dynamic module, compiled
  /// from a project in its parent's state. Its remote actions run on the
  /// device, it never sees its parent's state or actions, and it can't
  /// change the app's language or theme (it shows the parent's).
  final bool sandboxed;

  /// Whether app.yaml's `start:` action runs (off in the layout check, which
  /// shows the initial state).
  final bool runStart;

  /// Runs app.yaml's `start:` action, if any: when the app is created and
  /// when [_reset] starts it over, never on [reload] (the state is kept).
  void _runStartAction() {
    final start = config.start;
    if (!runStart || start == null) return;
    // After this build: the action may emit right away.
    Future.microtask(() async {
      try {
        await config.program.action(start, bloc.state);
      } catch (e, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: e,
          stack: stack,
          library: 'metacode',
          context: ErrorDescription('while running the start action "$start"'),
        ));
      }
    });
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
      dynamicModule: _dynamicModule,
      moduleRenderer: (name) => _child(name)?._renderer,
      moduleNode: _moduleNode,
      onAction: (context) => _host.actionFrom(context),
      readFile: config.readFile,
      initialState: config.initialState,
    );
    config.program.host = _host = CoreHost(
      bloc: bloc,
      navigation: config.navigation,
      navigatorKey: navigatorKey,
      locale: locale,
      render: render,
      resetModule: _resetModule,
      moduleCall: _moduleCall,
      sandboxed: sandboxed,
      remote: _remote,
    );
  }

  /// `core.modules.<name>.*` from this app's code: runs the module's action
  /// or value on its own state, or opens its route.
  Future<Object?> _moduleCall(
      String name, String op, Map<String, dynamic> args) async {
    final child = _child(name);
    if (child == null) {
      debugPrint('metacode: unknown module "$name"');
      return null;
    }
    final renderer = child._renderer;
    final language = renderer.language(
        locale.locale ?? WidgetsBinding.instance.platformDispatcher.locale);
    final params = {
      '_locale': ?language,
      if (args.containsKey('value')) 'value': args['value'],
    };
    switch (op) {
      case 'module.action':
        await child.config.program
            .action(args['name'] as String, child.bloc.state, params);
        return null;
      case 'module.value':
        return renderer.value(args['name'] as String, child.bloc.state, params);
      case 'module.push':
        await child._host.push(args['route'] as String);
        return null;
    }
    return null;
  }

  /// The module [name]'s page or component [id] (with [args], when it is
  /// a component called with arguments), in its own state and theme.
  Widget _moduleNode(String name, String id, Map? args,
      Map<String, dynamic> params) {
    final child = _child(name);
    if (child == null) {
      return Text('Unknown module "$name"',
          style: const TextStyle(color: Colors.red));
    }
    return ListenableBuilder(
      listenable: child,
      builder: (context, _) => KeyedSubtree(
        key: ValueKey('$name.$id#${child._generation}'),
        child: child._themed(
            context, child._renderer.buildNode(id, args, params)),
      ),
    );
  }

  /// A module compiled from [project] (a `metacodeProject`): sandboxed,
  /// reloaded in place whenever the project changes.
  Widget _dynamicModule(Object? project) =>
      DynamicModule(project: project, locale: locale, client: client);

  /// Bumped by [_reset], so the module's embeds start over (a fresh
  /// navigator when contained, fresh widget state either way).
  int _generation = 0;

  void _resetModule(String name) {
    final child = _child(name);
    if (child == null) {
      debugPrint('metacode: cannot reset unknown module "$name"');
      return;
    }
    child._reset();
  }

  /// This app's state back to its initial one (saved), and its modules'.
  /// Its `remote` and `shared` fields stay: they're the backend's.
  void _reset() {
    final scopes = config.scopes;
    bloc.setState({
      ...config.initialState,
      for (final e in bloc.state.entries)
        if (scopes[e.key] == 'remote' || scopes[e.key] == 'shared')
          e.key: e.value,
    });
    for (final child in _children.values) {
      child._reset();
    }
    _generation++;
    notifyListeners();
    _runStartAction();
  }

  /// Runs [config], a new version of this app (a regenerated or downloaded
  /// bundle), and the new versions of the modules created so far. The state
  /// carries over (see [StateBloc.reconfigure]).
  void reload(ProjectConfig config) {
    _config = config;
    bloc.reconfigure(config);
    _startRemote();
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

  /// A ui/ widget of this app (or a module's, `food.MenuPage`). Each page
  /// and component inside it rebuilds only when the values it reads change
  /// (or the app is reloaded). A module's routes opened over the whole app
  /// keep the module's style.
  Widget render(String id) {
    final dot = id.indexOf('.');
    if (dot > 0) {
      return _moduleNode(id.substring(0, dot), id.substring(dot + 1), null,
          const {});
    }
    return ListenableBuilder(
      listenable: this,
      builder: (context, _) => isModule
          ? _themed(context, _renderer.build(id))
          : _renderer.build(id));
  }

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

  /// The module [name] as a mini app (see [miniApp]). A reset
  /// (`core.modules.reset`) rebuilds it from scratch.
  Widget embed(String name) {
    final child = _child(name);
    if (child == null) {
      return Text('Unknown module "$name"',
          style: const TextStyle(color: Colors.red));
    }
    return child.miniApp;
  }

  /// This app as a compact app: its initial route with its own navigator,
  /// so its routes open inside its box (which must have a bounded size),
  /// themed by its own style/ if it has one.
  Widget get miniApp => ListenableBuilder(
        listenable: this,
        builder: (context, _) => _themed(
            context,
            _ContainedModule(
                key: ValueKey('${bloc.app.join('/')}#$_generation'),
                home: home)),
      );

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
      runStart: runStart,
      sandboxed: sandboxed,
      link: _link,
    );
  }

  /// Closes the modules' state (this app's bloc belongs to whoever made it).
  @override
  void dispose() {
    _remote?.dispose();
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
