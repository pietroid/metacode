import 'package:flutter_test/flutter_test.dart';

import '../generated/state.dart';
import 'fixtures.dart';

void main() {
  test('updateIdea sets the idea and resets the demo', () async {
    final s = await app.updateIdea(sample(buildStep: 5), 'Plant tracker');
    expect(s.idea, 'Plant tracker');
    expect(s.buildStep, 0);
  });

  test('makeApp walks the four steps, then is ready', () async {
    final s = await app.makeApp(sample(idea: 'Plant tracker'));
    expect(s.buildStep, 5);
    expect(app.emitted, [
      {'buildStep': 1},
      {'buildStep': 2},
      {'buildStep': 3},
      {'buildStep': 4},
      {'buildStep': 5},
    ]);
  });

  test('makeApp does nothing while a build is running', () async {
    await app.makeApp(sample(buildStep: 2));
    expect(app.emitted, isEmpty);
  });

  test('picking an idea fills it in and builds', () async {
    final s = await app.pickBills(sample());
    expect(s.idea, 'Split bills with roommates');
    expect(s.buildStep, 5);
    expect(app.ideaIsBills(s), isTrue);
  });

  test('openWaitlist pushes the sheet, close pops it', () async {
    await app.openWaitlist(sample());
    expect(app.navigation, ['push waitlist']);
    await app.close(sample());
    expect(app.navigation, ['pop']);
  });

  test('updateEmail clears an invalid status', () async {
    final s = await app.updateEmail(sample(waitlistStatus: WaitlistStatus.invalid), 'a@b.co');
    expect(s.email, 'a@b.co');
    expect(s.waitlistStatus, WaitlistStatus.idle);
  });

  test('joinWaitlist validates the email', () async {
    for (final bad in ['', 'ada', 'ada@', 'ada@site', '@site.com', 'ada@site.']) {
      final s = await app.joinWaitlist(sample(email: bad));
      expect(s.waitlistStatus, WaitlistStatus.invalid, reason: bad);
      expect(s.waitlistCount, 1284);
    }
  });

  test('joinWaitlist joins once', () async {
    final s = await app.joinWaitlist(sample(email: ' ada@example.com '));
    expect(s.waitlistStatus, WaitlistStatus.joined);
    expect(s.email, 'ada@example.com');
    expect(s.waitlistCount, 1285);
    expect((await app.joinWaitlist(s)).waitlistCount, 1285);
  });

  test('carousel wraps around and jumps to a slide', () async {
    expect((await app.nextExample(sample(exampleIndex: 3))).exampleIndex, 0);
    expect((await app.previousExample(sample(exampleIndex: 0))).exampleIndex, 3);
    expect((await app.showWork(sample())).exampleIndex, 2);
  });

  test('makeLikeThis sets the idea and opens the waitlist', () async {
    final s = await app.makeLikeThis(sample(exampleIndex: 1));
    expect(s.idea, 'Teach me guitar, ten minutes a day');
    expect(app.navigation, ['push waitlist']);
  });

  test('food servings add, remove and clear', () async {
    var s = await app.addFood(sample(), 1);
    s = await app.addFood(s, 1);
    expect(s.foods[1].count, 2);
    s = await app.removeFood(s, 1);
    expect(s.foods[1].count, 1);
    expect((await app.removeFood(sample(), 0)).foods[0].count, 0);
    expect((await app.clearFoods(s)).foods[1].count, 0);
  });

  test('chords and practice', () async {
    expect((await app.toggleChord(sample(), 1, true)).chords[1].learned, isTrue);
    expect((await app.logPractice(sample(practiceMinutes: 5))).practiceMinutes, 10);
  });

  test('jobs and taxes', () async {
    expect((await app.toggleJobPaid(sample(), 0, true)).jobs[0].paid, isTrue);
    expect((await app.setTaxRate(sample(), 20.4)).taxRate, 20);
  });

  test('plants: water resets, next day counts down', () async {
    expect((await app.waterPlant(sample(), 0)).plants[0].daysLeft, 3);
    final s = await app.nextDay(sample());
    expect([s.plants[0].daysLeft, s.plants[1].daysLeft], [0, 1]);
  });
}
