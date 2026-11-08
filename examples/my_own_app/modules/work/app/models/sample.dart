// sample: test fixtures. `app` runs actions and values like the engine;
// `sample(...)` builds a State (every field has a default).
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

/// Runs actions and values through the compiled program, like the engine.
final app = TestApp();

/// A small state to start tests from.
State sample({
  List<Message>? messages,
  List<FollowUp>? followUps,
  List<Task>? tasks,
  List<Event>? events,
  num selectedDay = 0,
}) => State(
  messages:
      messages ??
      [
        Message(sender: 'Marta Silva', subject: 'Budget', time: '8:42', unread: true),
        Message(sender: 'Legal', subject: 'NDA', time: 'Yesterday', unread: false),
      ],
  followUps:
      followUps ??
      [
        FollowUp(person: 'Tom', topic: 'SOW', dueIn: -2, done: false),
        FollowUp(person: 'Marta', topic: 'Headcount', dueIn: 0, done: false),
        FollowUp(person: 'Northwind', topic: 'Security', dueIn: 3, done: true),
      ],
  tasks:
      tasks ??
      [
        Task(title: 'Review budget', project: 'Finance', urgent: true, done: false),
        Task(title: 'Expenses', project: 'Ops', urgent: false, done: true),
      ],
  events:
      events ??
      [
        Event(day: 0, time: '9:30', title: 'Standup', important: false),
        Event(day: 0, time: '11:00', title: 'Budget review', important: true),
        Event(day: 2, time: '14:00', title: 'Planning', important: false),
      ],
  selectedDay: selectedDay,
);
