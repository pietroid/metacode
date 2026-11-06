import 'package:app_ui/app_ui.dart';
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
}
