import 'package:baby_vax/app/core/imports/import_manger.dart';

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
        binding: SignupBinding())
  ];
}
