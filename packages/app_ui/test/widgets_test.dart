import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [Ui] backed by a map of binding values that records action calls.
class FakeUi implements Ui {
  @override
  final BuildContext context;
  final Map<String, dynamic> bindings;
  final Set<String> actions;
  final List<(String, Map<String, dynamic>)> calls;
  final Map<String, dynamic> params;

  FakeUi(this.context, this.bindings, this.actions, this.calls,
      [this.params = const {}]);

  @override
  Widget node(dynamic node) {
    if (node == null) return const SizedBox.shrink();
    if (node is Map && node.length == 1) {
      final type = node.keys.first as String;
      return widget(type, normalizeProps(widgetCatalog[type]!, node[type])!);
    }
    return Text('${resolve(node)}');
  }

  @override
  List<Widget> nodes(dynamic nodes) => [for (final n in nodes as List) node(n)];

  @override
  Widget widget(String type, Map<String, dynamic> props) =>
      widgetBuilders[type]!(this, props);

  @override
  dynamic binding(dynamic name) => bindings[name];

  @override
  dynamic resolve(dynamic value) =>
      bindings.containsKey(value) ? bindings[value] : value;

  @override
  VoidCallback? action(dynamic name) =>
      actions.contains(name) ? () => calls.add((name as String, params)) : null;

  @override
  ValueChanged<T>? actionWithValue<T>(dynamic name) => actions.contains(name)
      ? (v) => calls.add((name as String, {...params, 'value': v}))
      : null;

  @override
  Ui withParams(Map<String, dynamic> extra) =>
      FakeUi(context, bindings, actions, calls, {...params, ...extra});
}

/// Renders [yaml] (a single widget node) and returns the recorded actions.
Future<List<(String, Map<String, dynamic>)>> render(
  WidgetTester tester,
  Map<String, dynamic> yaml, {
  Map<String, dynamic> bindings = const {},
  Set<String> actions = const {},
}) async {
  final calls = <(String, Map<String, dynamic>)>[];
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => FakeUi(context, bindings, actions, calls).node(yaml),
      ),
    ),
  ));
  return calls;
}

String fmt((String, Map<String, dynamic>) call) => '${call.$1} ${call.$2}';

void main() {
  testWidgets('match shows the case for the binding value', (tester) async {
    await render(tester, {
      'match': {
        'value': 'page',
        'cases': {'home': 'Home view', 'settings': 'Settings view'},
        'default': 'Not found',
      },
    }, bindings: {'page': 'settings'});
    expect(find.text('Settings view'), findsOneWidget);
    expect(find.text('Home view'), findsNothing);
  });

  testWidgets('navigationBar selects and reports the tapped index',
      (tester) async {
    final calls = await render(tester, {
      'navigationBar': {
        'destinations': [
          {'icon': 'home', 'label': 'Home'},
          {'icon': 'settings', 'label': 'Settings'},
        ],
        'selected': 'tab',
        'onSelected': 'goTo',
      },
    }, bindings: {'tab': 0}, actions: {'goTo'});
    await tester.tap(find.text('Settings'));
    expect(fmt(calls.single), 'goTo {value: 1}');
  });

  testWidgets('gridView builds items with index', (tester) async {
    final calls = await render(tester, {
      'gridView': {
        'data': 'items',
        'columns': 3,
        'itemBuilder': {
          'card': {'child': 'Item', 'onTap': 'open'},
        },
      },
    }, bindings: {'items': [1, 2, 3]}, actions: {'open'});
    expect(find.text('Item'), findsNWidgets(3));
    await tester.tap(find.text('Item').at(2));
    expect(fmt(calls.single), 'open {index: 2}');
  });

  testWidgets('toggle, slider and dropdown pass their value', (tester) async {
    final calls = await render(tester, {
      'column': [
        {'toggle': {'value': 'on', 'label': 'Dark mode', 'onChanged': 'set'}},
        {'slider': {'value': 'level', 'min': 0, 'max': 10, 'onChanged': 'set'}},
        {'dropdown': {'value': 'size', 'options': ['S', 'M', 'L'], 'onChanged': 'set'}},
      ],
    }, bindings: {'on': false, 'level': 5, 'size': 'M'}, actions: {'set'});

    await tester.tap(find.text('Dark mode'));
    expect(fmt(calls.last), 'set {value: true}');

    await tester.drag(find.byType(Slider), const Offset(60, 0));
    expect(calls.last.$2['value'], isA<double>());

    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('L').last);
    expect(fmt(calls.last), 'set {value: L}');
  });

  testWidgets('buttons with icons and tappable run actions', (tester) async {
    final calls = await render(tester, {
      'column': [
        {'filledButton': {'text': 'Save', 'icon': 'check', 'onPressed': 'save'}},
        {'outlinedButton': {'text': 'Cancel', 'onPressed': 'cancel'}},
        {'tappable': {'child': 'Row', 'onTap': 'open'}},
      ],
    }, actions: {'save', 'cancel', 'open'});
    await tester.tap(find.text('Save'));
    await tester.tap(find.text('Cancel'));
    await tester.tap(find.text('Row'));
    expect(calls.map((c) => c.$1), ['save', 'cancel', 'open']);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('content and layout widgets render', (tester) async {
    await render(tester, {
      'scroll': {
        'column': {
          'spacing': 8,
          'children': [
            {'container': {'padding': 8, 'color': 'primaryContainer', 'radius': 12, 'child': 'Boxed'}},
            {'avatar': {'text': 'PD'}},
            {'progress': {'value': 0.5}},
            {'divider': {}},
            {'stack': ['Under', 'Over']},
            {'text': {'value': 'Title', 'style': {'variant': 'titleLarge'}}},
            {'row': [{'text': 'L'}, {'spacer': {}}, {'text': 'R'}]},
          ],
        },
      },
    });
    for (final t in ['Boxed', 'PD', 'Under', 'Over', 'Title', 'L', 'R']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('textField reports changes and submits', (tester) async {
    final calls = await render(tester, {
      'textField': {'label': 'Name', 'onChanged': 'edit', 'onSubmitted': 'save'},
    }, actions: {'edit', 'save'});
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(calls.map(fmt), ['edit {value: Ana}', 'save {value: Ana}']);
  });
}
