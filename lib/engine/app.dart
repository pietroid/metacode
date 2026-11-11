import 'package:app_ui/app_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

import 'app_runtime.dart';
import 'locale.dart';
import 'project_config.dart';
import 'state_bloc.dart';

/// The running app: the initial navigation/ route, themed from style/, with
/// actions wired to the state, http and the navigator. Modules (`module:`
/// widgets) run inside it with their own state (see [AppRuntime]).
///
/// On the web and desktop all text is selectable, like a web page (pages,
/// sheets and dialogs alike); clickable widgets keep their text out of the
/// selection (app_ui's `Clickable`). Not an app setting.
///
/// Localized with Flutter's localization: the languages are the root
/// app's labels files (app/views/labels/), the locale is the device's
/// unless one was picked with `core.locale.set` (saved with the state), and
/// every app shows the labels file that fits it (engine/locale.dart).
///
/// Expects the root app's [StateBloc] above it. A new [config] (a new
/// version of the app) replaces the running one in place, keeping the
/// state; open routes rebuild with it.
class MetacodeApp extends StatefulWidget {
  final ProjectConfig config;

  /// HTTP client for remote actions' `api` run on the device and the
  /// backend link (tests pass a fake).
  final http.Client? client;

  /// Overrides style/'s theme mode.
  final ThemeMode? themeMode;

  /// Whether text is selectable; by default on the web and desktop (where
  /// there is a mouse), not on phones.
  final bool? selectableText;

  /// Whether app.yaml's `start:` actions run (see [AppRuntime.runStart]).
  final bool runStart;

  const MetacodeApp({
    super.key,
    required this.config,
    this.client,
    this.themeMode,
    this.selectableText,
    this.runStart = true,
  });

  static bool get _mousePlatform =>
      kIsWeb ||
      switch (defaultTargetPlatform) {
        TargetPlatform.macOS ||
        TargetPlatform.windows ||
        TargetPlatform.linux =>
          true,
        _ => false,
      };

  @override
  State<MetacodeApp> createState() => _MetacodeAppState();
}

class _MetacodeAppState extends State<MetacodeApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppRuntime _runtime;
  late final AppLocale _locale;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<StateBloc>();
    _locale = AppLocale(store: bloc.store)
      ..load()
      ..loadTheme();
    _runtime = AppRuntime(
      config: widget.config,
      bloc: bloc,
      navigatorKey: _navigatorKey,
      locale: _locale,
      client: widget.client,
      runStart: widget.runStart,
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
    _locale.dispose();
    super.dispose();
  }

  /// The root app's languages, the default first (Flutter's fallback).
  static List<Locale> _supportedLocales(ProjectConfig config) {
    final languages = {
      ?config.defaultLanguage,
      ...config.labels.keys,
    };
    return languages.isEmpty
        ? const [Locale('en')]
        : [for (final l in languages) languageLocale(l)];
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _locale, builder: _app);

  Widget _app(BuildContext context, Widget? _) {
    final config = widget.config;
    return MaterialApp(
      title: config.projectName,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      locale: _locale.locale,
      supportedLocales: _supportedLocales(config),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: MetacodeTheme.build(config.style, Brightness.light),
      darkTheme: MetacodeTheme.build(config.style, Brightness.dark),
      // The user's pick (core.theme.set) wins over the host's default.
      themeMode: _locale.themeMode ??
          widget.themeMode ??
          MetacodeTheme.mode(config.style),
      builder: widget.selectableText ?? MetacodeApp._mousePlatform
          ? (context, navigator) => _SelectableApp(child: navigator!)
          : null,
      home: _runtime.home,
    );
  }
}

/// One [SelectionArea] around the navigator, so every route's text can be
/// selected. Selection needs an [Overlay] above it (handles, the context
/// menu), and the navigator's own is below, so this hosts one whose single
/// entry always shows the latest [child].
class _SelectableApp extends StatefulWidget {
  final Widget child;

  const _SelectableApp({required this.child});

  @override
  State<_SelectableApp> createState() => _SelectableAppState();
}

class _SelectableAppState extends State<_SelectableApp> {
  late final _entry =
      OverlayEntry(builder: (_) => SelectionArea(child: widget.child));

  @override
  void didUpdateWidget(_SelectableApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}
