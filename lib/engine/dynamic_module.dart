import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../files/metacode_project.dart';
import 'app_runtime.dart';
import 'live_project.dart';
import 'locale.dart';
import 'state_bloc.dart';

/// A module compiled at runtime from [project], a `metacodeProject` (a
/// whole app as files, see lib/files/metacode_project.dart) that usually
/// lives in the embedding app's state: `miniApp: {project: <value>}`.
///
/// It is compiled in the app (lib/compiler, on a background isolate where
/// there is one) and runs as a mini app: its own state (in memory), program,
/// renderer and navigator. Every time [project] changes it is compiled again
/// and the running app is reloaded in place, its state kept, like a hot
/// reload. While a version doesn't compile, the last one that did keeps
/// running, under a banner with the first error.
///
/// It is sandboxed: it never sees the embedding app's state, actions or
/// values (it can't name them), has no backend, and can't change the app's
/// language or theme (`core.locale.set`, `core.theme.set` do nothing).
class DynamicModule extends StatefulWidget {
  final Object? project;
  final AppLocale locale;
  final http.Client? client;

  const DynamicModule(
      {super.key, required this.project, required this.locale, this.client});

  @override
  State<DynamicModule> createState() => _DynamicModuleState();
}

class _DynamicModuleState extends State<DynamicModule> {
  AppRuntime? _runtime;
  List<String> _errors = const [];

  /// The project last asked for (JSON), and the one being compiled.
  String? _wanted;
  bool _compiling = false;

  @override
  void initState() {
    super.initState();
    _changed();
  }

  @override
  void didUpdateWidget(DynamicModule old) {
    super.didUpdateWidget(old);
    _changed();
  }

  void _changed() {
    final source = jsonEncode(widget.project);
    if (source == _wanted) return;
    _wanted = source;
    _compile();
  }

  /// Compiles the latest project; a change during a compile compiles again
  /// after it, so the last version always wins.
  Future<void> _compile() async {
    if (_compiling) return;
    _compiling = true;
    try {
      String? done;
      while (mounted && done != _wanted) {
        done = _wanted;
        final result =
            await compileSources(projectToFiles(jsonDecode(done!)));
        if (!mounted || done != _wanted) continue;
        final config = result.config;
        setState(() {
          _errors = result.errors;
          if (config == null) return;
          final runtime = _runtime;
          if (runtime == null) {
            _runtime = AppRuntime(
              config: config,
              bloc: StateBloc(
                  config: config,
                  initial: Map<String, dynamic>.from(config.initialState)),
              navigatorKey: GlobalKey<NavigatorState>(),
              locale: widget.locale,
              client: widget.client,
              isModule: true,
              sandboxed: true,
            );
          } else {
            runtime.reload(config);
          }
        });
      }
    } catch (e, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: stack,
        library: 'metacode',
        context: ErrorDescription('while compiling a dynamic module'),
      ));
    } finally {
      _compiling = false;
    }
  }

  @override
  void dispose() {
    final runtime = _runtime;
    runtime?.dispose();
    runtime?.bloc.close();
    super.dispose();
  }

  /// Blank until the first version compiles (no spinner: it would keep
  /// every frame busy, tests' pumpAndSettle included).
  @override
  Widget build(BuildContext context) {
    final runtime = _runtime;
    final errors = _errors;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (runtime != null) runtime.miniApp,
        if (errors.isNotEmpty)
          Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: const Color(0xFFB3261E),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  errors.length == 1
                      ? errors.first
                      : '${errors.first}\n(+${errors.length - 1} more)',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
