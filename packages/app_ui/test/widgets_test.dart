import 'dart:typed_data';

import 'package:flutter_svg/flutter_svg.dart';
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
  final Map<String, Uint8List> files;

  FakeUi(this.context, this.bindings, this.actions, this.calls,
      [this.params = const {}, this.files = const {}]);

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
      buildCatalogWidget(this, type, props)!;

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
  Widget module(String name, {bool contained = false}) =>
      Text('module $name${contained ? ' contained' : ''}');

  @override
  Uint8List? file(String path) => files[path];

  @override
  Ui withParams(Map<String, dynamic> extra) =>
      FakeUi(context, bindings, actions, calls, {...params, ...extra}, files);
}

/// Renders [yaml] (a single widget node) and returns the recorded actions.
Future<List<(String, Map<String, dynamic>)>> render(
  WidgetTester tester,
  Map<String, dynamic> yaml, {
  Map<String, dynamic> bindings = const {},
  Set<String> actions = const {},
  Map<String, Uint8List> files = const {},
}) async {
  final calls = <(String, Map<String, dynamic>)>[];
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => FakeUi(context, bindings, actions, calls, const {}, files).node(yaml),
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

  testWidgets('a listView inside scroll lets drags over its items scroll the page',
      (tester) async {
    await render(tester, {
      'scroll': {
        'child': {
          'column': {
            'children': [
              {'sizedBox': {'height': 100}},
              {
                'listView': {
                  'data': 'items',
                  'itemBuilder': {'sizedBox': {'height': 80, 'child': 'Row'}},
                },
              },
            ],
          },
        },
      },
    }, bindings: {'items': List.generate(30, (i) => i)});
    final page = tester.state<ScrollableState>(find.byType(Scrollable).first);
    await tester.drag(find.text('Row').first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(page.position.pixels, greaterThan(300));
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
    expect(find.byIcon(phosphorIcons['regular']!['check']!), findsOneWidget);
  });

  testWidgets('enabled: false shows a button disabled and runs nothing', (tester) async {
    final calls = await render(tester, {
      'column': [
        {'filledButton': {'text': 'Save', 'onPressed': 'save', 'enabled': 'canSave'}},
        {'outlinedButton': {'text': 'Share', 'onPressed': 'share', 'enabled': 'canShare'}},
        {'iconButton': {'icon': 'add', 'onPressed': 'add', 'enabled': false}},
      ],
    }, bindings: {'canSave': false, 'canShare': true}, actions: {'save', 'share', 'add'});
    await tester.tap(find.text('Save'));
    await tester.tap(find.text('Share'));
    await tester.tap(find.byType(IconButton));
    expect(calls.map((c) => c.$1), ['share']);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });

  testWidgets('textField keyboard and progress color', (tester) async {
    await render(tester, {
      'column': [
        {'textField': {'keyboard': 'decimal', 'onChanged': 'edit'}},
        {'progress': {'value': 0.5, 'color': 'danger'}},
      ],
    }, actions: {'edit'});
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, const TextInputType.numberWithOptions(decimal: true));
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).color, isNotNull);
  });

  testWidgets('listView horizontal: one row scrolling sideways, items get index', (tester) async {
    await render(tester, {
      'listView': {'data': 'chips', 'itemBuilder': {'text': 'chipName'}, 'horizontal': true},
    }, bindings: {'chips': ['a', 'b', 'c'], 'chipName': 'Chip'});
    expect(find.text('Chip'), findsNWidgets(3));
    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    expect(scroll.scrollDirection, Axis.horizontal);
  });

  testWidgets('a scaffold shows its navigationBar as a rail on wide screens', (tester) async {
    final nav = {
      'scaffold': {
        'body': 'Body',
        'bottomBar': {
          'navigationBar': {
            'destinations': [{'icon': 'home', 'label': 'Home'}, {'icon': 'coffee', 'label': 'Menu'}],
            'selected': 'tab',
            'onSelected': 'pick',
          },
        },
      },
    };
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1200, 800);
    var calls = await render(tester, nav, bindings: {'tab': 0}, actions: {'pick'});
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byIcon(phosphorIcons['regular']!['coffee']!), findsOneWidget);
    await tester.tap(find.text('Menu'));
    expect(calls.map(fmt), ['pick {value: 1}']);

    tester.view.physicalSize = const Size(390, 800);
    calls = await render(tester, nav, bindings: {'tab': 0}, actions: {'pick'});
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
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

  testWidgets('responsive picks narrow or wide by width', (tester) async {
    final node = {
      'responsive': {'narrow': 'Phone', 'wide': 'Desktop', 'breakpoint': 600},
    };
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await render(tester, node);
    expect(find.text('Phone'), findsOneWidget);
    tester.view.physicalSize = const Size(1000, 800);
    await render(tester, node);
    await tester.pump();
    expect(find.text('Desktop'), findsOneWidget);
  });

  testWidgets('marquee scrolls its children in a loop', (tester) async {
    await render(tester, {
      'marquee': {'children': ['Ana made a plant app', 'Leo made a meal planner'], 'speed': 100},
    });
    expect(find.text('Ana made a plant app'), findsWidgets);
    final before = tester.getTopLeft(find.text('Ana made a plant app').first).dx;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(find.text('Ana made a plant app').first).dx, lessThan(before));
  });

  testWidgets('marquee stands still with reduced motion', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await render(tester, {'marquee': ['Still']});
    await tester.pumpAndSettle();
    expect(find.text('Still'), findsOneWidget);
  });

  testWidgets('container caps its width and draws a border', (tester) async {
    await render(tester, {
      'container': {'maxWidth': 300, 'borderColor': 'line', 'radius': 8, 'child': 'Capped'},
    });
    expect(tester.getSize(find.byType(Container)).width, 300);
    final box = tester.widget<Container>(find.byType(Container)).decoration as BoxDecoration;
    expect(box.border, isNotNull);
  });

  testWidgets('wrap centers its children', (tester) async {
    await render(tester, {
      'wrap': {'alignment': 'center', 'children': ['A']},
    });
    expect(tester.widget<Wrap>(find.byType(Wrap)).alignment, WrapAlignment.center);
  });

  testWidgets('text spans mix styles in one paragraph', (tester) async {
    await render(tester, {
      'text': {
        'spans': ['Get your ', {'value': 'what', 'style': {'color': 'primary'}}],
      },
    }, bindings: {'what': 'own app.'});
    expect(find.text('Get your own app.', findRichText: true), findsOneWidget);
  });

  testWidgets('image renders SVG files with SvgPicture', (tester) async {
    await render(tester, {
      'image': {'src': 'examples/my_own_app/app/views/style/images/logo.svg', 'width': 20, 'height': 30},
    });
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.getSize(find.byType(SvgPicture)), const Size(20, 30));
  });

  testWidgets('widgets that run an action on a click are Clickable',
      (tester) async {
    await render(tester, {
      'column': {
        'children': [
          {'filledButton': {'text': 'Go', 'onPressed': 'go'}},
          {'filledButton': {'text': 'Off', 'onPressed': 'missing'}},
          {'textField': {'onChanged': 'go'}},
        ],
      },
    }, actions: {'go'});
    expect(
        find.ancestor(of: find.text('Go'), matching: find.byType(Clickable)),
        findsOneWidget);
    final region = tester.widget<MouseRegion>(find
        .descendant(of: find.byType(Clickable), matching: find.byType(MouseRegion))
        .first);
    expect(region.cursor, SystemMouseCursors.click);
    // Disabled (not an action) and typed-into widgets are not.
    expect(
        find.ancestor(of: find.text('Off'), matching: find.byType(Clickable)),
        findsNothing);
    expect(
        find.ancestor(
            of: find.byType(TextField), matching: find.byType(Clickable)),
        findsNothing);
  });

  testWidgets('image reads app files from Ui.file when the engine has them',
      (tester) async {
    const png = 'examples/my_own_app/app/views/style/images/a.png';
    final bytes = Uint8List.fromList([137, 80, 78, 71]);
    await render(tester, {
      'image': {'src': png, 'width': 20, 'height': 30},
    }, files: {png: bytes});
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as MemoryImage).bytes, bytes);
  });
}
