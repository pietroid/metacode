// openProject: Opens the example app at `index` (projectNames) in the
// editor, its edits and history kept: puts the current draft and its
// history (projectCost, projectMs, projectTurns) away in `saved` (under
// projectName), then takes the picked one's from `saved`, or, the first time,
// loads its source through the remote loadProject (opening shows a spinner
// on its tile meanwhile), and pushes editRoute, where it starts anew;
// askError says why when it fails (askErrorText).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../.generated/api.dart';
import '../../.generated/core.dart';
import '../../.generated/remote.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/ask_error_text.dart';
import 'shared/project_names.dart';

Future<void> openProject(State state, void Function(StateDelta) emit,
    Core core, Remote remote, int index) async {
  if (state.opening != '') return;
  final names = projectNames();
  final name = names[index];
  final saved = <SavedDraft>[];
  SavedDraft? found;
  for (final SavedDraft s in state.saved) {
    if (s.name == name) found = s;
    if (s.name != state.projectName && s.name != name) saved.add(s);
  }
  if (state.projectName != '') {
    saved.add(SavedDraft(
        name: state.projectName,
        project: state.draft,
        cost: state.projectCost,
        ms: state.projectMs,
        turns: state.projectTurns));
  }
  if (found != null) {
    emit(StateDelta(
        saved: saved,
        draft: found.project,
        projectName: name,
        projectCost: found.cost,
        projectMs: found.ms,
        projectTurns: found.turns,
        runReply: '',
        runCost: 0,
        runMs: 0,
        runTurns: 0,
        askError: '',
        prompt: ''));
    await core.navigator.push(Routes.editRoute);
    return;
  }
  // `saved` after the call: the remote runs on the backend's copy of the
  // remote fields, so one emitted before it would be lost.
  emit(StateDelta(opening: name, askError: ''));
  final error = await remote.loadProject(name);
  if (error != null) {
    emit(StateDelta(opening: '', askError: askErrorText(error.code)));
    return;
  }
  emit(StateDelta(saved: saved, opening: '', prompt: ''));
  await core.navigator.push(Routes.editRoute);
}

void main() {
  final food = {'files': [], 'folders': []};
  final travel = {
    'files': [{'name': 'app.yaml', 'content': 'name: travel'}],
    'folders': [],
  };

  test('openProject loads the project and opens the editor', () async {
    app.api = (method, url, body) =>
        ApiResponse(status: 200, body: jsonEncode(food));
    final state = await app.openProject(sample(), 0);
    expect(app.requests, ['GET http://localhost:8787/project?name=food']);
    expect(state.draft.toJson(), food);
    expect(state.projectName, 'food');
    expect(state.opening, '');
    expect(app.navigation, ['push editRoute']);
  });

  test('openProject keeps the edits of the project it leaves', () async {
    final edited = sample().copyWith(
        projectName: 'travel',
        draft: MetacodeProject.fromJson(travel),
        projectCost: 0.5,
        projectMs: 60000,
        projectTurns: 4);
    app.api = (method, url, body) =>
        ApiResponse(status: 200, body: jsonEncode(food));
    final onFood = await app.openProject(edited, 0);
    expect(onFood.saved.length, 1);
    expect(onFood.saved[0].name, 'travel');
    expect(onFood.projectCost, 0);
    final back = await app.openProject(onFood, 1);
    expect(app.requests, isEmpty); // travel came from saved, not the bridge
    expect(back.projectName, 'travel');
    expect(back.draft.toJson(), travel);
    expect(back.projectCost, 0.5);
    expect(back.projectTurns, 4);
    expect(back.saved.map((s) => s.name), ['food']);
  });

  test('openProject stays on the picker when the bridge is down', () async {
    app.api = (method, url, body) => ApiResponse(status: 0, body: '');
    final state = await app.openProject(sample(), 1);
    expect(state.askError, contains('bridge'));
    expect(state.projectName, '');
    expect(app.navigation, isEmpty);
  });
}
