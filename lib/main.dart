import 'package:baby_vax/data/local/CashHelper.dart';
import 'package:baby_vax/provider/ProviderObserver.dart';
import 'package:baby_vax/view/login_screen/LoginScreen.dart';
import 'package:baby_vax/view/main_screen/MainHomeScreen.dart';
import 'package:baby_vax/view/onboarding_screen/OnboardingScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CashHelper.init();
  bool? isNewUser = CashHelper.getBool(key: 'isNewUser') ?? true;
  Widget? startWidget;
  if (isNewUser) {
    startWidget = OnboardingScreen();
  }else{
    startWidget = LoginScreen();
  }
  runApp(ProviderScope(
      observers: [MyProviderObserver()],
      child: MyApp(
        startWidget: startWidget,
      )));
}

class MyApp extends StatelessWidget {
  final Widget? startWidget;

  const MyApp({super.key, this.startWidget});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BabyVax',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: startWidget ?? const SizedBox(),
    );
  }
}
