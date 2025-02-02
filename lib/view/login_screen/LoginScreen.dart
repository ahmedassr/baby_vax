import 'package:baby_vax/shared/Components.dart';
import 'package:baby_vax/shared/ErrorHandler.dart';
import 'package:baby_vax/shared/style/Colors.dart';
import 'package:baby_vax/view/layout/Home.dart';
import 'package:baby_vax/view/login_screen/provider/LoginNotifier.dart';
import 'package:baby_vax/view/login_screen/provider/LoginStates.dart';
import 'package:baby_vax/view/signup_screen/SignupScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerWidget {
  LoginScreen({super.key});

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginNotifierProvider);
    final loginNotifier = ref.watch(loginNotifierProvider.notifier);
    ref.listen<LoginStates>(loginNotifierProvider, (prev, next) {
      if (next.error != null) {
        String niceError = ErrorHandler.getNiceErrorMessage(next.error.toString());
        myMsg(context: context, content: niceError, background: Colors.black.withOpacity(.8));
      }
      if(next.success){
        myNavigator(context, HomeLayout());
      }
    });
    return Scaffold(
      body: Form(
        key: formKey,
        child: Center(
          child: ListView(scrollDirection: Axis.vertical, children: [
            const SizedBox(
              height: 120,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  defaultButton(
                      width: 150,
                      background: loginState.inLoginScreen
                          ? primaryColor
                          : Colors.blueGrey,
                      radius: 0,
                      onPressed: () {
                        loginNotifier.toggleLoginScreen(context, true);
                      },
                      child: CustomBoldText(
                          title: 'تسجيل الدخول',
                          size: 18,
                          background: myWhiteColor)),
                  defaultButton(
                      width: 150,
                      background: !loginState.inLoginScreen
                          ? primaryColor
                          : Colors.blueGrey,
                      radius: 0,
                      onPressed: () {
                        loginNotifier.toggleLoginScreen(context, false);

                        myNavigator(context, SignupScreen());
                      },
                      child: CustomBoldText(
                          title: 'انشاء حساب',
                          size: 18,
                          background: myWhiteColor)),
                ],
              ),
            ),
            const SizedBox(
              height: 70,
            ),
            Padding(
                padding: const EdgeInsets.all(5),
                child: defaultFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    iconColor: primaryColor,
                    label: 'البريد الالكتروني',
                    labelColor: primaryColor,
                    borderColor: primaryColor,
                    validator: (value) {
                      if (value.isEmpty) {
                        return '! الرجاء ادخال البريد الالكتروني اولا';
                      }
                      return null;
                    },
                    prefixIcon: Icons.email_outlined)),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: passwordFormField(
                  controller: passwordController,
                  isVisible: loginState.isVisible,
                  label: 'كلمة المرور',
                  labelColor: primaryColor,
                  borderColor: primaryColor,
                  iconColor: primaryColor,
                  validator: (value) {
                    if (value.isEmpty) {
                      return '! الرجاء ادخال كلمة المرور اولا';
                    }
                    return null;
                  },
                  suffixIconOnPressed: () {
                    loginNotifier.togglePasswordIcon();
                  }),
            ),
            CustomBoldText(
                title: 'نسيت كلمة كلمة المرور؟',
                size: 14,
                textAlign: TextAlign.center,
                background: primaryColor),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: defaultButton(
                  width: double.infinity,
                  background: primaryColor,
                  radius: 25,
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      loginNotifier.userLogin(
                          email: emailController.text,
                          password: passwordController.text);
                    }
                  },
                  child: loginState.isLoading
                      ? const CircularProgressIndicator()
                      : CustomBoldText(
                          title: 'تسجيل الدخول',
                          size: 20,
                          background: myWhiteColor)),
            ),
            InkWell(
              onTap: () {
                loginNotifier.toggleLoginScreen(context, false);
                myNavigator(context, SignupScreen());
              },
              child: const Align(
                alignment: Alignment.center,
                child: Text(
                  'ليس لديك  حساب؟ انقر هنا لانشاء حساب جديد',
                  style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ]),
        ),
        // Color.fromRGBO(3, 129, 68, 1)
      ),
    );
  }
}
