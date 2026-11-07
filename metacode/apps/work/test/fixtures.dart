import '../generated/state.dart';
import '../generated/test_app.dart';

/// Runs actions and relations through the compiled program, like the engine.
final app = TestApp();

/// A small state to start tests from.
State sample({List<Job>? jobs, num taxRate = 10}) => State(
      jobs: jobs ??
          [
            Job(client: 'Bakery', task: 'Logo', amount: 800, paid: false),
            Job(client: 'Gym', task: 'Posts', amount: 1200, paid: true),
          ],
      taxRate: taxRate,
    );
