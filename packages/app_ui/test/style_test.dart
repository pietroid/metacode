import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('the Metacode style is valid and complete', () {
    expect(validateStyle(metacodeStyle), isEmpty);
    for (final mode in ['light', 'dark']) {
      final colors = (metacodeStyle['colors'] as Map)[mode] as Map;
      expect(colors.keys.toSet(), styleColorTokens.keys.toSet(), reason: mode);
    }
    expect((metacodeStyle['radius'] as Map).keys.toSet(),
        styleRadiusTokens.keys.toSet());
    expect((metacodeStyle['spacing'] as Map).keys.toSet(),
        styleSpacingTokens.keys.toSet());
    expect((metacodeStyle['sizes'] as Map).keys.toSet(),
        styleSizeTokens.keys.toSet());
    expect(typographyVariants.toSet(), textVariants.toSet());
  });

  test('resolveStyle merges a partial style over the defaults', () {
    final style = resolveStyle({
      'theme': 'dark',
      'colors': {
        'light': {'accent': '#123456'},
      },
      'radius': {'md': 0},
      'typography': {
        'bodyLarge': {'size': 17},
      },
    });
    expect(style['theme'], 'dark');
    expect(style['colors']['light']['accent'], '#123456');
    expect(style['colors']['light']['ink'], '#151514');
    expect(style['radius']['md'], 0.0);
    expect(style['radius']['sm'], 10.0);
    expect(style['typography']['bodyLarge']['size'], 17.0);
    expect(style['typography']['bodyLarge']['font'], 'text');
  });

  test("the app's style.yaml spells out exactly the Metacode style", () {
    // metacode/style.yaml documents the template; keep the two in sync.
    final file = File('../../metacode/style.yaml');
    expect(resolveStyle(loadYaml(file.readAsStringSync())),
        resolveStyle(metacodeStyle));
  });

  test('fonts can name families directly', () {
    final style = resolveStyle({
      'fonts': {'display': 'Figtree', 'text': 'system'},
    });
    expect(style['fonts'], {'display': 'Figtree', 'text': 'system'});
  });

  test('validateStyle reports bad tokens with paths', () {
    final issues = validateStyle({
      'theme': 'sepia',
      'fonts': {'display': 'Comic Sans'},
      'icons': {'weight': 'heavy'},
      'colors': {
        'light': {'accent': 'orange', 'glow': '#FFFFFF'},
      },
      'radius': {'md': -1},
      'typography': {
        'bodyLarge': {'font': 'mono', 'weight': 450},
        'huge': {'size': 90},
      },
      'shadows': {},
    }).map((i) => i.$1).toSet();
    expect(issues, {
      'theme',
      'fonts.display',
      'icons.weight',
      'colors.light.accent',
      'colors.light.glow',
      'radius.md',
      'typography.bodyLarge.font',
      'typography.bodyLarge.weight',
      'typography.huge',
      'shadows',
    });
  });

  testWidgets('the theme carries the tokens and the type roles',
      (tester) async {
    final style = resolveStyle({
      'fonts': {'display': 'Newsreader', 'text': 'Hanken Grotesk'},
      'icons': {'weight': 'light'},
      'colors': {
        'dark': {'accent': '#00FF00'},
      },
    });
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      theme: MetacodeTheme.build(style, Brightness.dark),
      home: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }),
    ));
    final tokens = MetacodeTokens.of(context);
    expect(tokens.accent, const Color(0xFF00FF00));
    expect(parseColor('accent', context), const Color(0xFF00FF00));
    expect(parseColor('red', context), tokens.color('danger'));
    final text = Theme.of(context).textTheme;
    expect(text.headlineMedium!.fontFamily, 'packages/app_ui/Newsreader');
    expect(text.labelLarge!.fontFamily, 'packages/app_ui/Hanken Grotesk');
    expect(parseIcon('wallet', context), phosphorIcons['light']!['wallet']);
    expect(Theme.of(context).scaffoldBackgroundColor, tokens.bg);
  });

  test('theme mode follows style.theme', () {
    expect(MetacodeTheme.mode(resolveStyle(null)), ThemeMode.system);
    expect(MetacodeTheme.mode(resolveStyle({'theme': 'light'})), ThemeMode.light);
  });
}
