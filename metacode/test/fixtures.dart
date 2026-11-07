import '../generated/state.dart';
import '../generated/test_app.dart';

/// Runs actions and bindings through the compiled program, like the engine.
final app = TestApp();

/// A small state to start tests from.
State sample({
  String idea = '',
  num buildStep = 0,
  String email = '',
  WaitlistStatus waitlistStatus = WaitlistStatus.idle,
  num waitlistCount = 1284,
  num exampleIndex = 0,
  List<Food>? foods,
  List<Chord>? chords,
  num practiceMinutes = 0,
  List<Job>? jobs,
  num taxRate = 10,
  List<Plant>? plants,
}) =>
    State(
      idea: idea,
      buildStep: buildStep,
      email: email,
      waitlistStatus: waitlistStatus,
      waitlistCount: waitlistCount,
      exampleIndex: exampleIndex,
      calorieGoal: 1000,
      foods: foods ??
          [
            Food(name: 'Oats', kcal: 300, protein: 10, count: 0),
            Food(name: 'Chicken', kcal: 400, protein: 40, count: 0),
          ],
      chords: chords ??
          [
            Chord(name: 'Em', fingers: 'two fingers', learned: true),
            Chord(name: 'G', fingers: 'three fingers', learned: false),
          ],
      practiceMinutes: practiceMinutes,
      jobs: jobs ??
          [
            Job(client: 'Bakery', task: 'Logo', amount: 800, paid: false),
            Job(client: 'Gym', task: 'Posts', amount: 1200, paid: true),
          ],
      taxRate: taxRate,
      plants: plants ??
          [
            Plant(name: 'Basil', everyDays: 3, daysLeft: 0),
            Plant(name: 'Cactus', everyDays: 14, daysLeft: 2),
          ],
    );
