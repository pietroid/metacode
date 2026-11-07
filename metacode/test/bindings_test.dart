import 'package:flutter_test/flutter_test.dart';

import '../generated/state.dart';
import 'fixtures.dart';

void main() {
  test('state.yaml loads and is usable', () {
    expect(app.waitlistCountText(app.initialState), isA<String>());
    expect(app.waitlistJoined(app.initialState), isFalse);
  });

  test('inputs', () {
    expect(app.ideaValue(sample(idea: 'x')), 'x');
    expect(app.emailValue(sample(email: 'a@b.co')), 'a@b.co');
    expect(app.ideaIsHabits(sample(idea: 'x')), isFalse);
    expect(app.ideaIsMeals(sample(idea: 'Plan meals for the week')), isTrue);
    expect(app.ideaIsBooks(sample(idea: 'Keep my book list')), isTrue);
  });

  test('waitlistCountText groups thousands', () {
    expect(app.waitlistCountText(sample()), '1,284 people are already on the list');
    expect(app.waitlistCountText(sample(waitlistCount: 999)), '999 people are already on the list');
    expect(app.waitlistCountText(sample(waitlistCount: 1234567)), '1,234,567 people are already on the list');
  });

  test('status flags', () {
    expect(app.waitlistInvalid(sample(waitlistStatus: WaitlistStatus.invalid)), isTrue);
    expect(app.waitlistJoined(sample(waitlistStatus: WaitlistStatus.joined)), isTrue);
  });

  test('ideaSummary and joinedText', () {
    expect(app.ideaSummary(sample()), contains('Tell us'));
    expect(app.ideaSummary(sample(idea: ' Plant tracker ')), contains('"Plant tracker"'));
    expect(app.joinedText(sample(email: 'a@b.co')), contains('a@b.co'));
  });

  test('build steps', () {
    final idle = sample();
    expect([app.step1State(idle), app.step4State(idle)], ['todo', 'todo']);
    expect(app.makeButtonText(idle), 'Make my app');
    final running = sample(buildStep: 3);
    expect([app.step1State(running), app.step2State(running), app.step3State(running), app.step4State(running)],
        ['done', 'done', 'doing', 'todo']);
    expect(app.makeButtonText(running), 'Making…');
    expect(app.buildReady(running), isFalse);
    final ready = sample(buildStep: 5);
    expect(app.step4State(ready), 'done');
    expect(app.buildReady(ready), isTrue);
    expect(app.makeButtonText(ready), 'Make it again');
  });

  test('carousel', () {
    expect(app.exampleKey(sample(exampleIndex: 2)), 'work');
    expect(app.exampleIsPlants(sample(exampleIndex: 3)), isTrue);
    expect(app.exampleImage(sample()), 'metacode/assets/food.jpg');
    expect(app.examplePosition(sample(exampleIndex: 1)), '2 of 4');
  });

  test('food totals and tips', () {
    expect(app.foodTip(sample()), contains('breakfast'));
    final oats = sample(foods: [Food(name: 'Oats', kcal: 300, protein: 10, count: 1)]);
    expect(app.caloriesText(oats), '300 of 1,000 kcal');
    expect(app.caloriesProgress(oats), closeTo(0.3, 0.001));
    expect(app.foodTip(oats), contains('low on protein'));
    final over = sample(foods: [Food(name: 'Pizza', kcal: 600, protein: 20, count: 2)]);
    expect(app.foodTip(over), contains('200 kcal over'));
    expect(app.caloriesProgress(over), 1.0);
    expect(app.foodInfo(oats, 0), '300 kcal · 10 g protein');
  });

  test('music progress and tips', () {
    expect(app.chordsText(sample()), '1 of 2 chords learned');
    expect(app.musicTip(sample()), startsWith('Next up: G.'));
    expect(app.practiceText(sample(practiceMinutes: 5)), '5 of 10 min today');
    expect(app.practiceProgress(sample(practiceMinutes: 20)), 1.0);
    final four = sample(chords: [
      for (final n in ['G', 'C', 'D', 'Em']) Chord(name: n, fingers: '', learned: true),
      Chord(name: 'F', fingers: '', learned: false),
    ]);
    expect(app.musicTip(four), contains('hundreds of pop songs'));
  });

  test('work totals, taxes and tip', () {
    expect(app.receivedText(sample()), '\$1,200');
    expect(app.waitingText(sample()), '\$800');
    expect(app.taxText(sample()), 'Set aside 10% for taxes: \$120');
    expect(app.workTip(sample()), contains('Bakery still owes you \$800'));
    expect(app.jobAmount(sample(), 1), '\$1,200');
  });

  test('plants status and tip', () {
    expect(app.plantStatus(sample(), 0), 'Water today');
    expect(app.plantStatus(sample(), 1), 'In 2 days');
    expect(app.plantsText(sample()), '1 plant needs water today');
    expect(app.plantTip(sample()), 'Water Basil today.');
    final done = sample(plants: [Plant(name: 'Fern', everyDays: 5, daysLeft: 1)]);
    expect(app.plantTip(done), 'All done. Next up: Fern tomorrow.');
  });
}
