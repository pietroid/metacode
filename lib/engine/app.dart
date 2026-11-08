import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'app_runtime.dart';
import 'project_config.dart';
import 'state_bloc.dart';

/// The running app: the initial navigation/ route, themed from style/, with
/// actions wired to the state, http and the navigator. Modules (`module:`
/// widgets) run inside it with their own state (see [AppRuntime]).
///
/// Expects the root app's [StateBloc] above it. A new [config] (a new
/// version of the app) replaces the running one in place, keeping the
/// state; open routes rebuild with it.
class MetacodeApp extends StatefulWidget {
  final ProjectConfig config;

  /// HTTP client for `core.api` (tests pass a fake).
  final http.Client? client;

  /// Overrides style/'s theme mode.
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
  late final AppRuntime _runtime;

  @override
  void initState() {
    super.initState();
    _runtime = AppRuntime(
      config: widget.config,
      bloc: context.read<StateBloc>(),
      navigatorKey: _navigatorKey,
      client: widget.client,
    );
  }

  @override
  void didUpdateWidget(MetacodeApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config) {
      _runtime.reload(widget.config);
    }
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

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
      home: _runtime.home,
    );
  }
}
