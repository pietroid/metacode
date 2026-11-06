import '../generated/state.dart';
import '../generated/test_app.dart';

/// Runs actions and bindings through the compiled program, like the engine.
final app = TestApp();

/// A small state to start tests from.
State sample({Filter filter = Filter.all, String draft = ''}) => State(
      tasks: [
        Task(title: 'Buy milk', done: false, createdAt: DateTime(2026, 11, 5)),
        Task(title: 'Walk the dog', done: true, createdAt: DateTime(2026, 11, 4)),
      ],
      draft: draft,
      filter: filter,
    );
