import 'package:baby_vax/app/config/constant/app_colors.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/widget/app_text.dart';
import 'package:baby_vax/app/modules/splash/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          context.isDarkMode ? AppColors.cardDark : AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SlideTransition(
              position: controller.logoSlide,
              child: ScaleTransition(
                scale: controller.logoScale,
                child: Image.asset(
                  'assets/appIcon.png',
                  width: 120,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: controller.textOpacity,
              child: const AppText(
                text: 'Baby Vax',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF42A332),
                ),
              ),
            ),
            const SizedBox(height: 6),
            FadeTransition(
              opacity: controller.textOpacity,
              child: const AppText(
                text: 'Care • Protection • Growth',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
