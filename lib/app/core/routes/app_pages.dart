import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/routes/app_routes.dart';
import 'package:baby_vax/app/modules/auth/login/binding/login_binding.dart';
import 'package:baby_vax/app/modules/auth/login/view/login_view.dart';

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
  ];
}
