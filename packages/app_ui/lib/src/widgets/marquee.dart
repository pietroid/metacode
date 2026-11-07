import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../parsers.dart';
import '../ui.dart';

/// A row of children that scrolls sideways in a loop (a ticker). With
/// reduced motion (MediaQuery.disableAnimations) it is a plain scrollable row.
Widget buildMarquee(Ui ui, Map<String, dynamic> p) => _Marquee(
      spacing: parseDouble(p['spacing']) ?? 24,
      speed: parseDouble(p['speed']) ?? 30,
      children: ui.nodes(p['children']),
    );

class _Marquee extends StatefulWidget {
  final double spacing;
  final double speed;
  final List<Widget> children;
  const _Marquee({required this.spacing, required this.speed, required this.children});

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  late final Ticker _ticker = createTicker(_tick);
  final _scroll = ScrollController();
  double _offset = 0;
  Duration _last = Duration.zero;

  void _tick(Duration elapsed) {
    final width = (_key.currentContext?.findRenderObject() as RenderBox?)?.size.width ?? 0;
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (width <= 0) return;
    _offset = (_offset + dt * widget.speed) % width;
    if (_scroll.hasClients) _scroll.jumpTo(_offset);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still && _ticker.isActive) _ticker.stop();
    if (!still && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Widget _run({Key? key}) => Padding(
        key: key,
        padding: EdgeInsets.only(right: widget.spacing),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: widget.spacing,
          children: widget.children,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!_ticker.isActive) {
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: _run());
    }
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _run(key: _key),
        _run(),
        _run(),
      ]),
    );
  }
}
