import 'package:baby_vax/app/core/routes/app_pages.dart';
import 'package:baby_vax/app/core/routes/app_routes.dart';

import 'app/core/imports/import_manger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, _) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Baby Vax",
          initialRoute: AppRoutes.login,
          getPages: AppPages.routes,
        );
      },
    );
  }
}
