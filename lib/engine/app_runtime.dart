import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'core_host.dart';
import 'project_config.dart';
import 'state_bloc.dart';
import 'ui_renderer.dart';

/// One running app: its state, program, renderer and host. Apps are
/// recursive: an `app: <name>` widget embeds the sub-app `apps/<name>/`,
/// which gets its own [AppRuntime] (created on first use) with its own
/// state, so a change in a sub-app only rebuilds that sub-app.
///
/// All apps share one [navigatorKey]: a sub-app's routes open on top of
/// the whole app.
class AppRuntime {
  final ProjectConfig config;
  final StateBloc bloc;
  final GlobalKey<NavigatorState> navigatorKey;
  final http.Client? client;

  late final UiRenderer renderer = UiRenderer(
    ui: config.ui,
    program: config.program,
    bloc: bloc,
    embed: embed,
  );

  final _children = <String, AppRuntime>{};

  AppRuntime({
    required this.config,
    required this.bloc,
    required this.navigatorKey,
    this.client,
  }) {
    config.program.host = CoreHost(
      bloc: bloc,
      navigation: config.navigation,
      navigatorKey: navigatorKey,
      client: client,
      render: render,
    );
  }

  /// A ui/ widget of this app that rebuilds with its state.
  Widget render(String id) => BlocBuilder<StateBloc, Map<String, dynamic>>(
        bloc: bloc,
        builder: (context, state) => renderer.build(context, id, state),
      );

  /// The initial route's widget.
  Widget get home => render(config.navigation.initialRoute.widget);

  /// The sub-app [name], themed by its own style/ if it has one.
  Widget embed(String name) {
    final child = _child(name);
    if (child == null) {
      return Text('Unknown app "$name"',
          style: const TextStyle(color: Colors.red));
    }
    final home = child.home;
    if (!child.config.hasOwnStyle) return home;
    return Builder(
      builder: (context) => Theme(
        data: MetacodeTheme.build(
            child.config.style, Theme.of(context).brightness),
        child: home,
      ),
    );
  }

  AppRuntime? _child(String name) {
    final existing = _children[name];
    if (existing != null) return existing;
    final config = this.config.apps[name];
    if (config == null) return null;
    return _children[name] = AppRuntime(
      config: config,
      bloc: bloc.child(name, config),
      navigatorKey: navigatorKey,
      client: client,
    );
  }

  /// Closes the sub-apps' state (this app's bloc belongs to whoever made it).
  void dispose() {
    for (final child in _children.values) {
      child.dispose();
      child.bloc.close();
    }
    _children.clear();
  }
}
