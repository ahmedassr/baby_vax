import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/app_logo.dart';
import 'package:baby_vax/app/modules/splash/splash_controller.dart';

/// The Flutter half of the splash: the mark slides up and settles, then the
/// name and tagline fade in. It starts on the same colour as the native
/// splash, so the hand-over is invisible.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SlideTransition(
              position: controller.logoSlide,
              child: ScaleTransition(
                scale: controller.logoScale,
                child: const AppLogo(size: 120),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeTransition(
              opacity: controller.textOpacity,
              child: Column(
                children: <Widget>[
                  // The brand name is never translated.
                  Text(
                    'Baby Vax',
                    style: theme.textTheme.displaySmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "SplashView_tagline".tr,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
