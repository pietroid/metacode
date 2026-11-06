import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'action_runtime.dart';
import 'binding_runtime.dart';
import 'state_bloc.dart';

/// Renders the YAML UI tree into Flutter widgets.
///
/// The renderer dispatches each YAML node to a builder. Bindings are resolved
/// by calling functions in the `bindings/` package through [BindingRuntime];
/// user gestures submit new states via [ActionRuntime].
class UiRenderer {
  final Map<String, dynamic> ui;
  final BindingRuntime bindings;
  final ActionRuntime actions;
  final Set<String> bindingNames;
  final Set<String> actionNames;

  UiRenderer({
    required this.ui,
    required this.bindings,
    required this.actions,
  })  : bindingNames = _extractFunctionNames(bindings.source),
        actionNames = _extractFunctionNames(actions.source);

  static Set<String> _extractFunctionNames(String source) {
    // Top-level functions: `<ReturnType> name(` at column 0. Private (`_`)
    // helpers are excluded so they can't be invoked from the UI.
    final regex = RegExp(
      r'^[A-Za-z_][\w<>?, ]*\s+([a-zA-Z][a-zA-Z0-9_]*)\s*\(',
      multiLine: true,
    );
    return regex.allMatches(source).map((m) => m.group(1)!).toSet();
  }

  /// Build a widget from a YAML node.
  ///
  /// [state] is the current application state.
  /// [contextMap] is an optional map of local context, e.g. `{index: 0}` inside
  /// a list item builder. It is passed to bindings and forwarded as action
  /// params.
  Widget build(
    BuildContext context,
    dynamic node,
    Map<String, dynamic> state, {
    Map<String, dynamic> contextMap = const {},
  }) {
    if (node == null) {
      return const SizedBox.shrink();
    }

    if (node is String) {
      final widgets = ui['widgets'] as Map<String, dynamic>?;
      if (widgets != null && widgets.containsKey(node)) {
        return build(context, widgets[node], state, contextMap: contextMap);
      }
      if (bindingNames.contains(node)) {
        return _buildText(bindings.call(node, state, context: contextMap));
      }
      return _buildText(node);
    }

    if (node is Map) {
      final map = Map<String, dynamic>.from(node);
      if (map.isEmpty) return const SizedBox.shrink();

      final key = map.keys.first;
      final value = map[key];

      return switch (key) {
        'scaffold' => _buildScaffold(context, value, state, contextMap),
        'appBar' => _buildAppBar(context, value, state, contextMap),
        'column' => _buildColumn(context, value, state, contextMap),
        'row' => _buildRow(context, value, state, contextMap),
        'expanded' => _buildExpanded(context, value, state, contextMap),
        'center' => _buildCenter(context, value, state, contextMap),
        'padding' => _buildPadding(context, value, state, contextMap),
        'sizedBox' => _buildSizedBox(value),
        'text' => _buildTextWidget(context, value, state, contextMap),
        'textField' => _buildTextField(context, value, state, contextMap),
        'iconButton' => _buildIconButton(context, value, state, contextMap),
        'floatingActionButton' =>
          _buildFloatingActionButton(context, value, state, contextMap),
        'elevatedButton' =>
          _buildElevatedButton(context, value, state, contextMap),
        'textButton' => _buildTextButton(context, value, state, contextMap),
        'listView' => _buildListView(context, value, state, contextMap),
        'listTile' => _buildListTile(context, value, state, contextMap),
        'checkbox' => _buildCheckbox(context, value, state, contextMap),
        'wrap' => _buildWrap(context, value, state, contextMap),
        'choiceChip' => _buildChoiceChip(context, value, state, contextMap),
        'icon' => _buildIcon(value),
        'if' => _buildIf(context, value, state, contextMap),
        _ => _buildText('Unsupported widget: $key'),
      };
    }

    return _buildText(node.toString());
  }

  Widget _buildText(dynamic value) {
    return Text(value?.toString() ?? '');
  }

  TextStyle? _parseStyle(Map<String, dynamic>? style) {
    if (style == null) return null;
    return TextStyle(
      fontSize: (style['fontSize'] as num?)?.toDouble(),
      fontWeight: _parseFontWeight(style['fontWeight']),
      color: _parseColor(style['color']),
    );
  }

  FontWeight? _parseFontWeight(dynamic value) {
    return switch (value) {
      'bold' || 'w700' => FontWeight.bold,
      'w100' => FontWeight.w100,
      'w200' => FontWeight.w200,
      'w300' => FontWeight.w300,
      'w400' => FontWeight.w400,
      'w500' => FontWeight.w500,
      'w600' => FontWeight.w600,
      'w800' => FontWeight.w800,
      'w900' => FontWeight.w900,
      _ => null,
    };
  }

  Color? _parseColor(dynamic value) {
    if (value is! String) return null;
    final hex = value.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return switch (value) {
      'red' => Colors.red,
      'green' => Colors.green,
      'blue' => Colors.blue,
      'black' => Colors.black,
      'white' => Colors.white,
      'grey' => Colors.grey,
      _ => null,
    };
  }

  IconData? _parseIcon(String? name) {
    return switch (name) {
      'add' => Icons.add,
      'delete' => Icons.delete,
      'inbox' => Icons.inbox,
      'check' => Icons.check,
      'close' => Icons.close,
      _ => Icons.circle,
    };
  }

  List<Widget> _buildChildren(
    BuildContext context,
    dynamic value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    if (value is List) {
      return value
          .map((child) => build(context, child, state, contextMap: contextMap))
          .toList();
    }
    return [build(context, value, state, contextMap: contextMap)];
  }

  void _runAction(
    BuildContext context,
    String? actionName,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
    Map<String, dynamic> extraParams,
  ) {
    if (actionName == null || !actionNames.contains(actionName)) return;
    final params = Map<String, dynamic>.from(contextMap)..addAll(extraParams);
    final newState = actions.call(actionName, state, params: params);
    context.read<StateBloc>().setState(newState);
  }

  Widget _buildScaffold(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    return Scaffold(
      appBar: value['appBar'] != null
          ? _buildAppBar(context, value['appBar'], state, contextMap)
              as PreferredSizeWidget
          : null,
      body: value['body'] != null
          ? build(context, value['body'], state, contextMap: contextMap)
          : null,
      floatingActionButton: value['floatingActionButton'] != null
          ? build(context, value['floatingActionButton'], state,
              contextMap: contextMap)
          : null,
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final title = value['title'];
    return AppBar(
      title: title != null
          ? build(context, title, state, contextMap: contextMap)
          : null,
      actions: value['actions'] != null
          ? _buildChildren(context, value['actions'], state, contextMap)
          : null,
      backgroundColor: _parseColor(value['backgroundColor']),
    );
  }

  Widget _buildColumn(
    BuildContext context,
    dynamic value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final children = value is List
        ? _buildChildren(context, value, state, contextMap)
        : _buildChildren(
            context, value['column'] ?? value['children'], state, contextMap);
    final props = value is Map ? value : const <String, dynamic>{};
    return Column(
      mainAxisAlignment: _parseMainAxisAlignment(props['mainAxisAlignment']),
      crossAxisAlignment:
          _parseCrossAxisAlignment(props['crossAxisAlignment']),
      children: children,
    );
  }

  Widget _buildRow(
    BuildContext context,
    dynamic value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final children = value is List
        ? _buildChildren(context, value, state, contextMap)
        : _buildChildren(
            context, value['row'] ?? value['children'], state, contextMap);
    final props = value is Map ? value : const <String, dynamic>{};
    return Row(
      mainAxisAlignment: _parseMainAxisAlignment(props['mainAxisAlignment']),
      crossAxisAlignment:
          _parseCrossAxisAlignment(props['crossAxisAlignment']),
      children: children,
    );
  }

  MainAxisAlignment _parseMainAxisAlignment(dynamic value) {
    return switch (value) {
      'start' => MainAxisAlignment.start,
      'end' => MainAxisAlignment.end,
      'center' => MainAxisAlignment.center,
      'spaceBetween' => MainAxisAlignment.spaceBetween,
      'spaceAround' => MainAxisAlignment.spaceAround,
      'spaceEvenly' => MainAxisAlignment.spaceEvenly,
      _ => MainAxisAlignment.start,
    };
  }

  CrossAxisAlignment _parseCrossAxisAlignment(dynamic value) {
    return switch (value) {
      'start' => CrossAxisAlignment.start,
      'end' => CrossAxisAlignment.end,
      'center' => CrossAxisAlignment.center,
      'stretch' => CrossAxisAlignment.stretch,
      'baseline' => CrossAxisAlignment.baseline,
      _ => CrossAxisAlignment.center,
    };
  }

  Widget _buildExpanded(
    BuildContext context,
    dynamic value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    if (value is Map && (value['expanded'] != null || value['child'] != null)) {
      final child = value['expanded'] ?? value['child'];
      return Expanded(
        flex: (value['flex'] as int?) ?? 1,
        child: build(context, child, state, contextMap: contextMap),
      );
    }
    return Expanded(
      child: build(context, value, state, contextMap: contextMap),
    );
  }

  Widget _buildCenter(
    BuildContext context,
    dynamic value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final child = value is Map ? (value['center'] ?? value['child']) : value;
    return Center(
      child: build(context, child, state, contextMap: contextMap),
    );
  }

  Widget _buildPadding(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    EdgeInsetsGeometry padding = EdgeInsets.zero;
    if (value['all'] != null) {
      padding = EdgeInsets.all((value['all'] as num).toDouble());
    } else {
      padding = EdgeInsets.only(
        left: (value['left'] as num?)?.toDouble() ?? 0,
        right: (value['right'] as num?)?.toDouble() ?? 0,
        top: (value['top'] as num?)?.toDouble() ?? 0,
        bottom: (value['bottom'] as num?)?.toDouble() ?? 0,
      );
      final h = (value['horizontal'] as num?)?.toDouble();
      final v = (value['vertical'] as num?)?.toDouble();
      if (h != null || v != null) {
        padding = EdgeInsets.symmetric(horizontal: h ?? 0, vertical: v ?? 0);
      }
    }
    return Padding(
      padding: padding,
      child: build(context, value['child'], state, contextMap: contextMap),
    );
  }

  Widget _buildSizedBox(Map<String, dynamic> value) {
    return SizedBox(
      width: (value['width'] as num?)?.toDouble(),
      height: (value['height'] as num?)?.toDouble(),
    );
  }

  Widget _buildTextWidget(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    dynamic content = value['text'] ?? value['value'];
    if (content is String && bindingNames.contains(content)) {
      content = bindings.call(content, state, context: contextMap);
    }
    return Text(
      content?.toString() ?? '',
      style: _parseStyle(value['style']),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final bindingName = value['value'];
    final currentValue = bindingName is String && bindingNames.contains(bindingName)
        ? bindings.call(bindingName, state, context: contextMap).toString()
        : (bindingName ?? '').toString();
    final hint = value['hint']?.toString();
    final actionName = value['onChanged']?.toString();

    return TextFormField(
      initialValue: currentValue,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: actionName != null
          ? (text) => _runAction(
                context,
                actionName,
                state,
                contextMap,
                {'value': text},
              )
          : null,
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final actionName = value['onPressed']?.toString();
    return IconButton(
      icon: Icon(_parseIcon(value['icon']?.toString())),
      tooltip: value['tooltip']?.toString(),
      onPressed: actionName != null
          ? () => _runAction(context, actionName, state, contextMap, {})
          : null,
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final actionName = value['onPressed']?.toString();
    return FloatingActionButton(
      onPressed: actionName != null
          ? () => _runAction(context, actionName, state, contextMap, {})
          : null,
      child: build(context, value['child'], state, contextMap: contextMap),
    );
  }

  Widget _buildElevatedButton(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final actionName = value['onPressed']?.toString();
    return ElevatedButton(
      onPressed: actionName != null
          ? () => _runAction(context, actionName, state, contextMap, {})
          : null,
      child: build(context, value['child'], state, contextMap: contextMap),
    );
  }

  Widget _buildTextButton(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final actionName = value['onPressed']?.toString();
    final text = value['text'];
    return TextButton(
      onPressed: actionName != null
          ? () => _runAction(context, actionName, state, contextMap, {})
          : null,
      child: text != null
          ? build(context, text, state, contextMap: contextMap)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildListView(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final dataBinding = value['data']?.toString();
    final items = dataBinding != null && bindingNames.contains(dataBinding)
        ? bindings.call(dataBinding, state, context: contextMap) as List
        : <dynamic>[];

    if (items.isEmpty) {
      return build(context, value['empty'], state, contextMap: contextMap);
    }

    final itemBuilder = value['itemBuilder'];
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final childContext = Map<String, dynamic>.from(contextMap)
          ..['index'] = index;
        return build(ctx, itemBuilder, state, contextMap: childContext);
      },
    );
  }

  Widget _buildListTile(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    return ListTile(
      title: value['title'] != null
          ? build(context, value['title'], state, contextMap: contextMap)
          : null,
      subtitle: value['subtitle'] != null
          ? build(context, value['subtitle'], state, contextMap: contextMap)
          : null,
      leading: value['leading'] != null
          ? build(context, value['leading'], state, contextMap: contextMap)
          : null,
      trailing: value['trailing'] != null
          ? build(context, value['trailing'], state, contextMap: contextMap)
          : null,
      onTap: value['onTap'] != null
          ? () => _runAction(
                context,
                value['onTap'].toString(),
                state,
                contextMap,
                {},
              )
          : null,
    );
  }

  Widget _buildCheckbox(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final bindingName = value['value']?.toString();
    final checked = bindingName != null && bindingNames.contains(bindingName)
        ? bindings.call(bindingName, state, context: contextMap) == true
        : false;
    final actionName = value['onChanged']?.toString();

    return Checkbox(
      value: checked,
      onChanged: actionName != null
          ? (_) => _runAction(context, actionName, state, contextMap, {})
          : null,
    );
  }

  Widget _buildWrap(
    BuildContext context,
    dynamic value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final children = value is List
        ? _buildChildren(context, value, state, contextMap)
        : _buildChildren(
            context, value['children'] ?? value['wrap'], state, contextMap);
    final props = value is Map ? value : const <String, dynamic>{};
    return Wrap(
      spacing: (props['spacing'] as num?)?.toDouble() ?? 0,
      children: children,
    );
  }

  Widget _buildChoiceChip(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final selectedBinding = value['selected']?.toString();
    final selected = selectedBinding != null &&
            bindingNames.contains(selectedBinding)
        ? bindings.call(selectedBinding, state, context: contextMap) == true
        : false;
    final actionName = value['onSelected']?.toString();

    return ChoiceChip(
      label: build(context, value['label'], state, contextMap: contextMap),
      selected: selected,
      onSelected: actionName != null
          ? (_) => _runAction(context, actionName, state, contextMap, {})
          : null,
    );
  }

  Widget _buildIcon(Map<String, dynamic> value) {
    return Icon(
      _parseIcon(value['name']?.toString()),
      size: (value['size'] as num?)?.toDouble(),
      color: _parseColor(value['color']),
    );
  }

  Widget _buildIf(
    BuildContext context,
    Map<String, dynamic> value,
    Map<String, dynamic> state,
    Map<String, dynamic> contextMap,
  ) {
    final condition = value['condition']?.toString();
    final passes = condition != null && bindingNames.contains(condition)
        ? bindings.call(condition, state, context: contextMap) == true
        : false;
    if (passes) {
      return build(context, value['then'], state, contextMap: contextMap);
    }
    if (value['else'] != null) {
      return build(context, value['else'], state, contextMap: contextMap);
    }
    return const SizedBox.shrink();
  }
}
