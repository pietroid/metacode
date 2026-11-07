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
}
