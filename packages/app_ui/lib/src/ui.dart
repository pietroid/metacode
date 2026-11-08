import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Everything a widget builder needs from the engine.
///
/// Builders never see state, bindings or actions directly: they ask [Ui].
abstract class Ui {
  BuildContext get context;

  /// Builds a child node (widget id, binding, inline widget or literal text).
  Widget node(dynamic node);

  /// Builds a list of child nodes.
  List<Widget> nodes(dynamic nodes);

  /// Builds a catalog widget from an already-normalized property map.
  Widget widget(String type, Map<String, dynamic> props);

  /// The value of a binding, or null if [name] is not a binding.
  dynamic binding(dynamic name);

  /// A binding's value if [value] names one, otherwise [value] itself.
  dynamic resolve(dynamic value);

  /// A callback that runs the action, or null if [name] is not an action
  /// (which disables the widget, like Flutter's null callbacks).
  VoidCallback? action(dynamic name);

  /// Like [action], passing the input's new value as the `value` param.
  ValueChanged<T>? actionWithValue<T>(dynamic name);

  /// The module `modules/<name>/`, running with its own state, actions and
  /// values.
  Widget module(String name);

  /// A [Ui] whose bindings and actions also receive [params]
  /// (e.g. `{'index': i}` for list items).
  Ui withParams(Map<String, dynamic> params);

  /// The bytes of the app file [path] (`examples/my_own_app/app/views/
  /// style/images/logo.svg`) when the engine runs from the project's files,
  /// so an edited image shows without rebuilding the app; null otherwise
  /// (then it is a bundled asset).
  Uint8List? file(String path);
}

/// Builds one catalog widget from its properties.
typedef UiWidgetBuilder = Widget Function(Ui ui, Map<String, dynamic> props);
