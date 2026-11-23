import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter/scheduler.dart';

/// Marks where a screen's content first appears, so the [AppEntrance]s
/// under it can play a short staggered entrance (polish §2.2).
///
/// Entrances only play during the first [window] after the scope is first
/// built. A row that scrolls out and back later, or a card rebuilt by a
/// refresh, simply appears: content never re-animates while the parent is
/// reading it.
class AppEntranceScope extends StatefulWidget {
  const AppEntranceScope({super.key, required this.child});

  final Widget child;

  /// How long after the scope appears entrances still play.
  static const Duration window = Duration(milliseconds: 600);

  @override
  State<AppEntranceScope> createState() => _AppEntranceScopeState();
}

class _AppEntranceScopeState extends State<AppEntranceScope> {
  late final Duration _start = _now();

  static Duration _now() => SchedulerBinding.instance.currentFrameTimeStamp;

  @override
  Widget build(BuildContext context) =>
      _EntranceClock(start: _start, child: widget.child);
}

class _EntranceClock extends InheritedWidget {
  const _EntranceClock({required this.start, required super.child});

  final Duration start;

  @override
  bool updateShouldNotify(_EntranceClock old) => old.start != start;
}

/// Fades [child] in while it rises 12dp, 200 ms with the standard
/// decelerate curve, [index] × 40 ms after its siblings (capped at the
/// sixth). Plays only inside a fresh [AppEntranceScope] and never with
/// "Remove animations" on.
class AppEntrance extends StatefulWidget {
  const AppEntrance({super.key, required this.child, this.index = 0});

  final Widget child;

  /// Position among the items entering together; sets the stagger.
  final int index;

  static const Duration stagger = Duration(milliseconds: 40);
  static const int maxStaggered = 5;
  static const double rise = 12;

  @override
  State<AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<AppEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final _EntranceClock? clock =
        context.dependOnInheritedWidgetOfExactType<_EntranceClock>();
    if (clock == null || AppMotion.reduced(context)) return;
    final Duration age =
        SchedulerBinding.instance.currentFrameTimeStamp - clock.start;
    if (age > AppEntranceScope.window) return;

    final Duration delay =
        AppEntrance.stagger * widget.index.clamp(0, AppEntrance.maxStaggered);
    final Duration total = delay + AppMotion.medium;
    final AnimationController c =
        AnimationController(vsync: this, duration: total);
    _controller = c;
    _t = CurvedAnimation(
      parent: c,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1,
          curve: AppMotion.enter),
    );
    c.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double>? t = _t;
    if (t == null) return widget.child;
    return AnimatedBuilder(
      animation: t,
      child: widget.child,
      builder: (BuildContext context, Widget? child) => Opacity(
        opacity: t.value,
        child: Transform.translate(
          offset: Offset(0, AppEntrance.rise * (1 - t.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Wraps each item of [children] in an [AppEntrance] with a rising index,
/// leaving plain spacers ([SizedBox]) as they are.
List<Widget> staggeredEntrance(List<Widget> children) {
  int i = 0;
  return <Widget>[
    for (final Widget c in children)
      if (c is SizedBox && c.child == null)
        c
      else
        AppEntrance(index: i++, child: c),
  ];
}
