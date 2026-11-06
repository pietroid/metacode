// Bindings are pure Dart functions that the engine evaluates at runtime via
// dart_eval. Each binding receives the current state as a JSON string and an
// optional context JSON string (e.g. the current list index), and returns a
// JSON-encoded value.

import 'dart:convert';

String _filteredTasksJson(dynamic state) {
  final tasks = state['tasks'];
  final filter = state['filter'];
  final result = [];
  for (var i = 0; i < tasks.length; i++) {
    final task = tasks[i];
    if (filter == 'done') {
      if (task['done'] == true) result.add(task);
    } else if (filter == 'open') {
      if (task['done'] != true) result.add(task);
    } else {
      result.add(task);
    }
  }
  return jsonEncode(result);
}

String _completedCount(dynamic state) {
  final tasks = state['tasks'];
  var count = 0;
  for (var i = 0; i < tasks.length; i++) {
    if (tasks[i]['done'] == true) count++;
  }
  return count.toString();
}

String taskList(String stateJson, [String contextJson = '{}']) {
  final state = jsonDecode(stateJson);
  return _filteredTasksJson(state);
}

String taskCount(String stateJson, [String contextJson = '{}']) {
  final state = jsonDecode(stateJson);
  final filtered = jsonDecode(_filteredTasksJson(state));
  return jsonEncode(filtered.length);
}

String draftValue(String stateJson, [String contextJson = '{}']) {
  final state = jsonDecode(stateJson);
  return jsonEncode(state['draft'] ?? '');
}

String taskTitle(String stateJson, String contextJson) {
  final state = jsonDecode(stateJson);
  final context = jsonDecode(contextJson);
  final index = context['index'];
  final filtered = jsonDecode(_filteredTasksJson(state));
  return jsonEncode(filtered[index]['title']);
}

String taskDone(String stateJson, String contextJson) {
  final state = jsonDecode(stateJson);
  final context = jsonDecode(contextJson);
  final index = context['index'];
  final filtered = jsonDecode(_filteredTasksJson(state));
  return jsonEncode(filtered[index]['done'] == true);
}

String taskDate(String stateJson, String contextJson) {
  final state = jsonDecode(stateJson);
  final context = jsonDecode(contextJson);
  final index = context['index'];
  final filtered = jsonDecode(_filteredTasksJson(state));
  return jsonEncode(filtered[index]['createdAt'] ?? '');
}

String hasCompletedTasks(String stateJson, [String contextJson = '{}']) {
  final state = jsonDecode(stateJson);
  final tasks = state['tasks'];
  for (var i = 0; i < tasks.length; i++) {
    if (tasks[i]['done'] == true) return 'true';
  }
  return 'false';
}

String clearCompletedText(String stateJson, [String contextJson = '{}']) {
  final state = jsonDecode(stateJson);
  return jsonEncode('${_completedCount(state)} completed');
}

String filterIsAll(String stateJson, [String contextJson = '{}']) {
  final state = jsonDecode(stateJson);
  return jsonEncode(state['filter'] == 'all');
}

String filterIsOpen(String stateJson, [String contextJson = '{}']) {
  final state = jsonDecode(stateJson);
  return jsonEncode(state['filter'] == 'open');
}

String filterIsDone(String stateJson, [String contextJson = '{}']) {
  final state = jsonDecode(stateJson);
  return jsonEncode(state['filter'] == 'done');
}
