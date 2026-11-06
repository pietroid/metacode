import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every spec has a builder and every builder has a spec', () {
    expect(widgetBuilders.keys.toSet(), widgetCatalog.keys.toSet());
  });

  test('inline props point at catalog widgets', () {
    for (final spec in widgetCatalog.values) {
      for (final entry in spec.props.entries) {
        if (entry.value == PropKind.inline) {
          expect(widgetCatalog, contains(spec.inline[entry.key]));
        }
      }
    }
  });

  test('shorthand props exist on the widget', () {
    for (final entry in widgetCatalog.entries) {
      final prop = entry.value.shorthand.prop;
      if (prop != null) {
        expect(entry.value.props, contains(prop), reason: entry.key);
      }
    }
  });

  test('every icon name is mapped', () {
    expect(icons.keys.toSet(), iconNames.toSet());
  });

  testWidgets('every color name and text variant resolves', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }),
    ));
    expect(themeColors(context).keys.toSet(), colorNames.toSet());
    expect(textVariantStyles(context).keys.toSet(), textVariants.toSet());
  });
}
