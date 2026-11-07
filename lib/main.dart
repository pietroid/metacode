import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'engine/app.dart';
import 'engine/project_config.dart';
import 'engine/state_bloc.dart';

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
