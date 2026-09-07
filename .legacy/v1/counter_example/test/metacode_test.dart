import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/counter_store.dart';
import '../lib/pages/home_page.dart';

void main() {
  testWidgets('When button is tapped, increment counter',
      (WidgetTester tester) async {
    final counterStore = CounterStore();
    await tester
        .pumpWidget(MaterialApp(home: HomePage(counterStore: counterStore)));
    final counterStoreBefore = counterStore.value;
    await tester.tap(find.byKey(const Key('counterButton')));
    await tester.pump();
    expect(counterStore.value, counterStoreBefore + 1);
  });

  test('When counter is incremented, increment the store', () {
    final counterStore = CounterStore(value: 2);
    counterStore.increment();
    expect(counterStore.value, 3);
  });

  testWidgets('Show counter value on the home page',
      (WidgetTester tester) async {
    final counterStore = CounterStore(value: 5);
    await tester
        .pumpWidget(MaterialApp(home: HomePage(counterStore: counterStore)));
    expect(find.text('5'), findsOneWidget);
  });
}
