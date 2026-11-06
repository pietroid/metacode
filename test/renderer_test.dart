// Renders metacode/ui.yaml through the engine + app_ui with the compiled
// program, and drives it with taps. Regenerate first: tool/check_engine.sh.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metacode/engine/program.dart';
import 'package:metacode/engine/project_config.dart';
import 'package:metacode/engine/state_bloc.dart';
import 'package:metacode/engine/ui_renderer.dart';
import 'package:yaml/yaml.dart';

void main() {
  final program = MetacodeProgram(
    ByteData.sublistView(File('metacode/generated/program.evc').readAsBytesSync()),
    jsonDecode(File('metacode/generated/manifest.json').readAsStringSync()),
  );
  final ui = yamlToDart(loadYaml(File('metacode/ui.yaml').readAsStringSync()));

  Future<StateBloc> pump(WidgetTester tester, Map<String, dynamic> state) async {
    final config = ProjectConfig(
      projectName: 'test',
      description: '',
      ui: ui,
      initialState: state,
      program: program,
    );
    final bloc = StateBloc(config: config, initial: state);
    final renderer = UiRenderer(ui: ui, program: program);
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        home: BlocBuilder<StateBloc, Map<String, dynamic>>(
          builder: (context, s) => renderer.build(context, 'homePage', s),
        ),
      ),
    ));
    return bloc;
  }

  Map<String, dynamic> state() => {
        'tasks': [
          {'title': 'Buy milk', 'done': false, 'createdAt': '2026-11-05'},
        ],
        'draft': '',
        'filter': 'all',
      };

  testWidgets('renders tasks and toggles one', (tester) async {
    final bloc = await pump(tester, state());
    expect(find.text('Task List'), findsOneWidget);
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Clear completed'), findsNothing);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(bloc.state['tasks'][0]['done'], true);
    expect(find.text('Clear completed'), findsOneWidget);
  });

  testWidgets('typing and adding a task clears the field', (tester) async {
    final bloc = await pump(tester, state());
    await tester.enterText(find.byType(TextField), 'Read');
    await tester.tap(find.byTooltip('Add task'));
    await tester.pump();
    expect((bloc.state['tasks'] as List).length, 2);
    expect(find.text('Read'), findsOneWidget); // in the list, not the field
  });

  testWidgets('shows the empty state', (tester) async {
    await pump(tester, {...state(), 'tasks': []});
    expect(find.text('No tasks yet'), findsOneWidget);
  });
}
