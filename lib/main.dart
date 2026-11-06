import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'engine/action_runtime.dart';
import 'engine/binding_runtime.dart';
import 'engine/project_config.dart';
import 'engine/state_bloc.dart';
import 'engine/ui_renderer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await ProjectConfig.load();
  final bloc = StateBloc(config: config);
  await bloc.initialize();

  runApp(
    BlocProvider<StateBloc>.value(
      value: bloc,
      child: MetacodeApp(config: config),
    ),
  );
}

class MetacodeApp extends StatelessWidget {
  final ProjectConfig config;

  const MetacodeApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final bindings = BindingRuntime(source: config.bindingsSource);
    final actions = ActionRuntime(source: config.actionsSource);
    final renderer = UiRenderer(
      ui: config.ui,
      bindings: bindings,
      actions: actions,
    );

    return MaterialApp(
      title: config.projectName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: BlocBuilder<StateBloc, Map<String, dynamic>>(
        builder: (context, state) {
          return renderer.build(
            context,
            'homePage',
            state,
          );
        },
      ),
    );
  }
}
