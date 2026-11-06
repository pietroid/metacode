// Actions are pure Dart functions that the engine evaluates at runtime via
// dart_eval. Each action receives the current state as a JSON string and a
// params JSON string, and returns a JSON-encoded new state.

import 'dart:convert';

String _today() {
  final now = DateTime.now();
  final year = now.year;
  final month = now.month;
  final day = now.day;
  var result = year.toString();
  result = result + '-';
  if (month < 10) result = result + '0';
  result = result + month.toString();
  result = result + '-';
  if (day < 10) result = result + '0';
  result = result + day.toString();
  return result;
}

int _findRealIndex(Map state, int visibleIndex) {
  final tasks = state['tasks'];
  final filter = state['filter'];
  var visibleCount = 0;
  for (var i = 0; i < tasks.length; i++) {
    final task = tasks[i] as Map;
    var matches = false;
    if (filter == 'all') {
      matches = true;
    } else if (filter == 'done' && task['done'] == true) {
      matches = true;
    } else if (filter == 'open' && task['done'] != true) {
      matches = true;
    }
    if (matches) {
      if (visibleCount == visibleIndex) return i;
      visibleCount++;
    }
  }
  return -1;
}

String addTask(String stateJson, String paramsJson) {
  final state = jsonDecode(stateJson) as Map;
  var title = state['draft'];
  if (title == null) title = '';
  if (title == '') {
    return stateJson;
  }
  final tasks = state['tasks'];
  final result = [];
  for (var i = 0; i < tasks.length; i++) {
    result.add(tasks[i]);
  }
  result.add({'title': title, 'done': false, 'createdAt': _today()});
  state['tasks'] = result;
  state['draft'] = '';
  return jsonEncode(state);
}

String updateDraft(String stateJson, String paramsJson) {
  final state = jsonDecode(stateJson) as Map;
  final params = jsonDecode(paramsJson) as Map;
  var value = params['value'];
  if (value == null) value = '';
  state['draft'] = value;
  return jsonEncode(state);
}

String toggleTask(String stateJson, String paramsJson) {
  final state = jsonDecode(stateJson) as Map;
  final params = jsonDecode(paramsJson) as Map;
  final visibleIndex = params['index'];
  final realIndex = _findRealIndex(state, visibleIndex);
  final tasks = state['tasks'];
  final result = [];
  for (var i = 0; i < tasks.length; i++) {
    if (i == realIndex) {
      final task = tasks[i] as Map;
      result.add({
        'title': task['title'],
        'done': task['done'] != true,
        'createdAt': task['createdAt'],
      });
    } else {
      result.add(tasks[i]);
    }
  }
  state['tasks'] = result;
  return jsonEncode(state);
}

String deleteTask(String stateJson, String paramsJson) {
  final state = jsonDecode(stateJson) as Map;
  final params = jsonDecode(paramsJson) as Map;
  final visibleIndex = params['index'];
  final realIndex = _findRealIndex(state, visibleIndex);
  final tasks = state['tasks'];
  final result = [];
  for (var i = 0; i < tasks.length; i++) {
    if (i != realIndex) result.add(tasks[i]);
  }
  state['tasks'] = result;
  return jsonEncode(state);
}

String clearCompleted(String stateJson, String paramsJson) {
  final state = jsonDecode(stateJson) as Map;
  final tasks = state['tasks'];
  final result = [];
  for (var i = 0; i < tasks.length; i++) {
    final task = tasks[i] as Map;
    if (task['done'] != true) result.add(task);
  }
  state['tasks'] = result;
  return jsonEncode(state);
}

String setFilterAll(String stateJson, String paramsJson) {
  final state = jsonDecode(stateJson) as Map;
  state['filter'] = 'all';
  return jsonEncode(state);
}

String setFilterOpen(String stateJson, String paramsJson) {
  final state = jsonDecode(stateJson) as Map;
  state['filter'] = 'open';
  return jsonEncode(state);
}

String setFilterDone(String stateJson, String paramsJson) {
  final state = jsonDecode(stateJson) as Map;
  state['filter'] = 'done';
  return jsonEncode(state);
}
