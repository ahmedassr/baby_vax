import 'package:baby_vax/app/core/binding/app_binding.dart';

import 'app/core/imports/import_manger.dart';
import 'app/core/service/init_app_service.dart';

final Logger logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAppService();
  final isDarkMode =
      AppConstant.getStorage.read(AppConstant.isDarkModeKey) ?? false;
  runApp(MyApp(
    isDarkMode: isDarkMode,
  ));
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;

  const MyApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: _checkLoginState(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final bool isLoggedIn = snapshot.data ?? false;
          return ScreenUtilInit(
            designSize: const Size(414, 896),
            builder: (context, _) {
              return GetMaterialApp(
                debugShowCheckedModeBanner: false,
                initialBinding: AppBinding(),
                title: "Baby Vax",
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
                initialRoute: isLoggedIn ? AppRoutes.mainMenu : AppRoutes.login,
                getPages: AppPages.routes,
              );
            },
          );
        });
  }

  Future<bool> _checkLoginState() {
    return Future.value(
        AppConstant.getStorage.read(AppConstant.isLoginKey) ?? false);
  }
}
