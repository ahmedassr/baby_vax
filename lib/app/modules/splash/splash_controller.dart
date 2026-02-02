import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/config/constant/app_constant.dart';
import 'package:baby_vax/app/core/routes/app_routes.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> logoScale;
  late Animation<Offset> logoSlide;
  late Animation<double> textOpacity;

  bool isLoggedIn = false;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    isLoggedIn = AppConstant.getStorage.read(AppConstant.isLoginKey) ?? false;

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    logoSlide = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    logoScale = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack),
      ),
    );

    textOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.9, 1, curve: Curves.easeIn),
      ),
    );


    animationController.forward();

    Future.delayed(const Duration(seconds: 4), () {
      Get.offAllNamed(
        isLoggedIn ? AppRoutes.mainMenu : AppRoutes.login,
      );
    });
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
