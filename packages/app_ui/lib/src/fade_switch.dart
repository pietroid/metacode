import 'package:flutter/widgets.dart';

import 'parsers.dart';

/// [child] (one of a widget's cases, identified by [id]) switched with a
/// fade when [ms] (the `fade:` prop) is set: the old case fades out during
/// the first half, then the new one fades in. Reduced motion: at once.
Widget fadeSwitch(BuildContext context, dynamic ms, Object id, Widget child) {
  final duration = parseDouble(ms)?.round() ?? 0;
  if (duration <= 0) return child;
  return _FadeSwitch(
      ms: duration, id: id, child: Leaving(leaving: false, child: child));
}

/// Marks a case that is fading out. It shows the state it had when it
/// started leaving: the engine's pages and components inside it stop
/// rebuilding (otherwise a case reading the same value as the switch would
/// already show the new case while it fades out).
class Leaving extends InheritedWidget {
  final bool leaving;

  const Leaving({super.key, required this.leaving, required super.child});

  /// Whether [context] is inside a case that is fading out.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Leaving>()?.leaving ?? false;

  @override
  bool updateShouldNotify(Leaving old) => leaving != old.leaving;
}

class _FadeSwitch extends StatefulWidget {
  final int ms;
  final Object id;

  /// The current case, wrapped in a [Leaving] (not leaving).
  final Widget child;

  const _FadeSwitch({required this.ms, required this.id, required this.child});

  @override
  State<_FadeSwitch> createState() => _FadeSwitchState();
}

class _FadeSwitchState extends State<_FadeSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1);
  }

  /// The case fading out, frozen, while [_controller] runs.
  (Object, Widget)? _previous;

  @override
  void didUpdateWidget(_FadeSwitch old) {
    super.didUpdateWidget(old);
    if (widget.id == old.id) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _previous = null;
      _controller.value = 1;
      return;
    }
    // The same Leaving widget type at the same place, so the old case keeps
    // its widget state; only the flag flips.
    _previous = (old.id, Leaving(leaving: true, child: (old.child as Leaving).child));
    _controller
      ..duration = Duration(milliseconds: widget.ms)
      ..forward(from: 0).whenCompleteOrCancel(() {
        if (mounted) setState(() => _previous = null);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previous = _previous;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        if (previous != null)
          FadeTransition(
            key: ValueKey(previous.$1),
            opacity: CurvedAnimation(
              parent: _controller,
              curve: const Interval(0, 0.5, curve: Curves.easeInOut),
            ).drive(Tween(begin: 1.0, end: 0.0)),
            child: previous.$2,
          ),
        FadeTransition(
          key: ValueKey(widget.id),
          opacity: previous == null
              ? const AlwaysStoppedAnimation(1.0)
              : CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.5, 1, curve: Curves.easeInOut),
                ),
          child: widget.child,
        ),
      ],
    );
  }
}
