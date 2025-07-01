import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/medical_date_details/binding/medical_date_details_binding.dart';
import 'package:baby_vax/app/modules/medical_date_details/view/medical_date_details_view.dart';
import 'package:baby_vax/app/modules/medical_dates/binding/medical_dates_binding.dart';
import 'package:baby_vax/app/modules/setting/binding/setting_binding.dart';
import 'package:baby_vax/app/modules/setting/view/setting_view.dart';
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
        route: AppRoutes.signup,
        page: () => const SignupView(),
        binding: SignupBinding()),
    build(
        route: AppRoutes.mainMenu,
        page: () => const MainMenuView(),
        binding: MainMenuBinding()),
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
        route: AppRoutes.medicalDatesDetails,
        page: () => const MedicalDateDetailsView(),
        binding: MedicalDateDetailsBinding()),
  ];
}
