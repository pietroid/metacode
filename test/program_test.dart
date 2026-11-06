// Runs the compiled program (metacode/generated/program.evc) exactly as the
// engine does. Regenerate first: `dart run tool/metacode.dart`.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:metacode/engine/program.dart';

void main() {
  late MetacodeProgram program;

  setUpAll(() {
    final bytes = File('metacode/generated/program.evc').readAsBytesSync();
    final manifest = jsonDecode(
      File('metacode/generated/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    program = MetacodeProgram(ByteData.sublistView(bytes), manifest);
  });

  Map<String, dynamic> state({String filter = 'all', String draft = ''}) => {
        'tasks': [
          {'title': 'Buy milk', 'done': false, 'createdAt': '2026-11-05'},
          {'title': 'Walk the dog', 'done': true, 'createdAt': '2026-11-04'},
        ],
        'draft': draft,
        'filter': filter,
      };

  test('addTask appends the draft and clears it', () {
    final next = program.action('addTask', state(draft: 'Read'));
    expect((next['tasks'] as List).length, 3);
    expect(next['tasks'][2]['title'], 'Read');
    expect(next['draft'], '');
  });

  test('addTask ignores an empty draft', () {
    expect((program.action('addTask', state())['tasks'] as List).length, 2);
  });

  test('updateDraft takes the input value', () {
    expect(program.action('updateDraft', state(), {'value': 'x'})['draft'], 'x');
  });

  test('toggleTask uses the index within the visible (filtered) list', () {
    final next = program.action('toggleTask', state(filter: 'done'), {'index': 0});
    expect(next['tasks'][1]['done'], false);
    expect(next['tasks'][0]['done'], false);
  });

  test('deleteTask and clearCompleted', () {
    expect((program.action('deleteTask', state(), {'index': 0})['tasks'] as List)
        .single['title'], 'Walk the dog');
    expect((program.action('clearCompleted', state())['tasks'] as List)
        .single['title'], 'Buy milk');
  });

  test('filter actions and bindings', () {
    final open = program.action('setFilterOpen', state());
    expect(open['filter'], 'open');
    expect(program.binding('filterIsOpen', open), true);
    expect((program.binding('taskList', open) as List).length, 1);
  });

  test('item bindings receive the index', () {
    final s = state();
    expect(program.binding('taskTitle', s, {'index': 1}), 'Walk the dog');
    expect(program.binding('taskDone', s, {'index': 1}), true);
    expect(program.binding('taskDate', s, {'index': 0}), '2026-11-05');
    expect(program.binding('clearCompletedText', s), '1 completed');
    expect(program.binding('hasCompletedTasks', s), true);
  });
}
