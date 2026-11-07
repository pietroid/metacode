import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'core_host.dart';
import 'project_config.dart';
import 'state_bloc.dart';
import 'ui_renderer.dart';

/// The running app: the initial navigation.yaml route, themed from
/// style.yaml, with actions wired to the state, http and the navigator.
///
/// Expects a [StateBloc] above it.
class MetacodeApp extends StatefulWidget {
  final ProjectConfig config;

  /// HTTP client for `core.api` (tests pass a fake).
  final http.Client? client;

  /// Overrides style.yaml's theme mode.
  final ThemeMode? themeMode;

  const MetacodeApp({
    super.key,
    required this.config,
    this.client,
    this.themeMode,
  });

  @override
  State<MetacodeApp> createState() => _MetacodeAppState();
}

class _MetacodeAppState extends State<MetacodeApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final _renderer =
      UiRenderer(ui: widget.config.ui, program: widget.config.program);

  @override
  void initState() {
    super.initState();
    widget.config.program.host = CoreHost(
      bloc: context.read<StateBloc>(),
      navigation: widget.config.navigation,
      navigatorKey: _navigatorKey,
      client: widget.client,
      render: _render,
    );
  }

  /// A ui.yaml widget that rebuilds with the state.
  Widget _render(String id) => BlocBuilder<StateBloc, Map<String, dynamic>>(
        builder: (context, state) => _renderer.build(context, id, state),
      );

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return MaterialApp(
      title: config.projectName,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: MetacodeTheme.build(config.style, Brightness.light),
      darkTheme: MetacodeTheme.build(config.style, Brightness.dark),
      themeMode: widget.themeMode ?? MetacodeTheme.mode(config.style),
      home: _render(config.navigation.initialRoute.widget),
    );
  }
}
