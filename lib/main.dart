import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'engine/app.dart';
import 'engine/project_config.dart';
import 'engine/state_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final source = await ProjectConfig.loadBundle();
  final config = ProjectConfig.fromBundle(jsonDecode(source) as Map);
  final bloc = StateBloc(config: config);
  await bloc.initialize();

  runApp(
    BlocProvider<StateBloc>.value(
      value: bloc,
      child: _LiveApp(config: config, source: source),
    ),
  );
}

/// Runs the app and, on every hot reload, reloads `bundle.json`: when it
/// changed (`dart run tool/metacode.dart watch` regenerates it on save),
/// the new version replaces the running one and the state is kept. The
/// same path a downloaded update would take.
class _LiveApp extends StatefulWidget {
  final ProjectConfig config;
  final String source;

  const _LiveApp({required this.config, required this.source});

  @override
  State<_LiveApp> createState() => _LiveAppState();
}

class _LiveAppState extends State<_LiveApp> {
  late ProjectConfig _config = widget.config;
  late String _source = widget.source;

  @override
  void reassemble() {
    super.reassemble();
    _reload();
  }

  Future<void> _reload() async {
    final source = await ProjectConfig.loadBundle();
    if (!mounted || source == _source) return;
    try {
      final config = ProjectConfig.fromBundle(jsonDecode(source) as Map);
      setState(() {
        _source = source;
        _config = config;
      });
      debugPrint('metacode: reloaded ${ProjectConfig.bundleAsset}');
    } catch (e) {
      // Mid-write or invalid: keep the running version.
      debugPrint('metacode: could not reload the bundle: $e');
    }
  }

  @override
  Widget build(BuildContext context) => MetacodeApp(config: _config);
}
