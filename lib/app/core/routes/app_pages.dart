import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/auth/forgot_password/binding/forgot_password_binding.dart';
import 'package:baby_vax/app/modules/auth/forgot_password/view/forgot_password_view.dart';
import 'package:baby_vax/app/modules/home/view/home_view.dart';
import 'package:baby_vax/app/modules/medical_date_details/binding/medical_date_details_binding.dart';
import 'package:baby_vax/app/modules/medical_date_details/view/medical_date_details_view.dart';
import 'package:baby_vax/app/modules/medical_dates/binding/medical_dates_binding.dart';
import 'package:baby_vax/app/modules/growth/binding/growth_binding.dart';
import 'package:baby_vax/app/modules/growth/view/growth_view.dart';
import 'package:baby_vax/app/modules/onboarding/binding/onboarding_binding.dart';
import 'package:baby_vax/app/modules/onboarding/view/onboarding_view.dart';
import 'package:baby_vax/app/modules/setting/binding/setting_binding.dart';
import 'package:baby_vax/app/modules/setting/view/setting_view.dart';
import 'package:baby_vax/app/modules/splash/splash_binding.dart';
import 'package:baby_vax/app/modules/splash/splash_view.dart';
import 'package:baby_vax/app/modules/tip_details/binding/tip_details_binding.dart';
import 'package:baby_vax/app/modules/tip_details/view/tip_details_view.dart';
import 'package:baby_vax/app/modules/tips/binding/tips_binding.dart';
import 'package:baby_vax/app/modules/tips/view/tips_view.dart';

class AppPages {
  static const String initial = AppRoutes.login;

  static GetPage build(
      {required String route,
      required GetPageBuilder page,
      Bindings? binding}) {
    return GetPage(name: route, page: page, binding: binding);
  }

  static final List<GetPage> routes = [
    build(
        route: AppRoutes.login,
        page: () => const LoginView(),
        binding: LoginBinding()),
    build(
        route: AppRoutes.forgotPassword,
        page: () => const ForgotPasswordView(),
        binding: ForgotPasswordBinding()),
    build(
        route: AppRoutes.signup,
        page: () => const SignupView(),
        binding: SignupBinding()),
    build(
        route: AppRoutes.mainMenu,
        page: () => const MainMenuView(),
        binding: MainMenuBinding()),
    build(
        route: AppRoutes.main,
        page: () => const HomeView(),
        binding: HomeBinding()),
    build(
        route: AppRoutes.medicalDates,
        page: () => const MedicalDatesView(),
        binding: MedicalDatesBinding()),
    build(
        route: AppRoutes.setting,
        page: () => const SettingsView(),
        binding: SettingsBinding()),
    build(
        route: AppRoutes.tips,
        page: () => const TipsView(),
        binding: TipsBinding()),
    build(
        route: AppRoutes.medicalDateDetails,
        page: () => const MedicalDateDetailsView(),
        binding: MedicalDateDetailsBinding()),
    build(
        route: AppRoutes.tipDetails,
        page: () => const TipDetailsView(),
        binding: TipDetailsBinding()),
    build(
        route: AppRoutes.editUser,
        page: () => const EditUserView(),
        binding: EditUserBinding()),
    build(
        route: AppRoutes.splash,
        page: () => const SplashView(),
        binding: SplashBinding()),
    build(
        route: AppRoutes.onboarding,
        page: () => const OnboardingView(),
        binding: OnboardingBinding()),
    build(
        route: AppRoutes.growth,
        page: () => const GrowthView(),
        binding: GrowthBinding()),
  ];
}
