import 'package:baby_vax/app/core/imports/import_core.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/imports/import_config.dart';
import 'package:baby_vax/app/core/widget/brand_mark.dart';

/// The Baby Vax mark, read by TalkBack as the app name.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88, this.hero = false});

  /// Height of the mark. Its width follows the artwork's 5:6 aspect.
  final double size;

  /// Whether this logo is where the splash's mark lands (sign-in and the
  /// introduction). Only one logo per screen may set it.
  final bool hero;

  /// The shared-element tag between the splash mark and the first screen.
  static const String heroTag = 'baby-vax-mark';

  /// During the flight the mark is drawn from its vector paths, cross-fading
  /// from the splash colours (light shield on green) to the logo's own
  /// (green shield), so the colours never jump.
  static Widget flightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final bool dark = Theme.of(toContext).brightness == Brightness.dark;
    final BrandMarkColors splash =
        dark ? BrandMarkColors.onSplashDark : BrandMarkColors.onSplashLight;
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? _) => CustomPaint(
        painter: BrandMarkPainter(BrandMarkColors.lerp(
            splash,
            BrandMarkColors.standard,
            AppMotion.standard.transform(animation.value))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.asset(
      AppImage.appLogo,
      height: size,
      width: size * 5 / 6,
      fit: BoxFit.contain,
      semanticLabel: 'Baby Vax',
    );
    if (!hero) return image;
    return Hero(
        tag: heroTag, flightShuttleBuilder: flightShuttle, child: image);
  }
}
