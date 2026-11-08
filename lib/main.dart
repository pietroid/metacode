import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'engine/app.dart';
import 'engine/files/open_project_files.dart';
import 'engine/live_project.dart';
import 'engine/project_config.dart';
import 'engine/state_bloc.dart';
import 'engine/state_store.dart';

/// Runs the project from its files when the platform has them (a folder
/// given with METACODE_PROJECT_DIR on desktop, localStorage on the web; see
/// engine/files/open_project_files.dart), recompiling on every change;
/// otherwise runs the bundled `bundle.json`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final files = await openProjectFiles();
  final live = files == null ? null : LiveProject(files);
  final config = await live?.compile() ??
      ProjectConfig.fromBundle(jsonDecode(await ProjectConfig.loadBundle()) as Map);
  // From the project's files, the state is saved with them
  // (`.state/state.yaml` next to each app's sources).
  final bloc = StateBloc(
    config: config,
    store: files != null
        ? FilesStateStore(files)
        : StateStore.platform(config.projectName),
  );
  await bloc.initialize();

  runApp(
    BlocProvider<StateBloc>.value(
      value: bloc,
      child: _LiveApp(config: config, live: live),
    ),
  );
}

/// Replaces the running app with every new version of the project (state
/// kept): each compile of [live], or, without live files, `bundle.json`
/// reloaded on hot reload.
class _LiveApp extends StatefulWidget {
  final ProjectConfig config;
  final LiveProject? live;

  const _LiveApp({required this.config, this.live});

  @override
  State<_LiveApp> createState() => _LiveAppState();
}

class _LiveAppState extends State<_LiveApp> {
  late ProjectConfig _config = widget.config;
  StreamSubscription<ProjectConfig>? _updates;
  String? _source;

  @override
  void initState() {
    super.initState();
    _updates = widget.live?.watch().listen((config) {
      if (mounted) setState(() => _config = config);
    });
  }

  @override
  void dispose() {
    _updates?.cancel();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (widget.live == null) _reloadBundle();
  }

  Future<void> _reloadBundle() async {
    final source = await ProjectConfig.loadBundle();
    if (!mounted || source == _source) return;
    try {
      final config = ProjectConfig.fromBundle(jsonDecode(source) as Map);
      setState(() {
        _source = source;
        _config = config;
      });
    } catch (e) {
      // Mid-write or invalid: keep the running version.
      debugPrint('metacode: could not reload the bundle: $e');
    }
  }

  @override
  Widget build(BuildContext context) => MetacodeApp(config: _config);
}
