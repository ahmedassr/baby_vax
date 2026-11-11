import 'package:baby_vax/app/core/imports/import_manger.dart';

/// A skeleton of the content that is loading: grey blocks the shape of
/// cards, pulsing gently.
///
/// Replaces v1.0's three different loaders (`AppShimmerLoading`,
/// `CupertinoActivityIndicator`, `CircularProgressIndicator`) with one, and
/// drops the `shimmer` package: a single opacity animation on the whole
/// skeleton costs one ticker, where a shimmer costs a shader per block.
class AppLoading extends StatefulWidget {
  const AppLoading({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 88,
    this.showHero = false,
  });

  /// How many card placeholders.
  final int itemCount;

  final double itemHeight;

  /// Add a taller block first, the shape of the home hero card.
  final bool showHero;

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect "remove animations" in accessibility settings.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _pulse.value = 1;
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color block = Theme.of(context).colorScheme.surfaceContainerHigh;
    Widget bar(double height) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration:
              BoxDecoration(color: block, borderRadius: AppRadius.lgAll),
        );

    return Semantics(
      label: "loading_label".tr,
      liveRegion: true,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _pulse,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: AppSpacing.screenVertical,
            children: <Widget>[
              if (widget.showHero) bar(180),
              for (int i = 0; i < widget.itemCount; i++) bar(widget.itemHeight),
            ],
          ),
        ),
      ),
    );
  }
}
