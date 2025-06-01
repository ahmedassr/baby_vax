import 'package:baby_vax/app/core/service/get_storage_service.dart';

import 'app/core/imports/import_manger.dart';
import 'app/core/service/init_app_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initAppService();
  AppConstant.uid = Get.find<GetStorageService>().read("uid");
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
          initialRoute:
               AppRoutes.login,
          getPages: AppPages.routes,
        );
      },
    );
  }
}
