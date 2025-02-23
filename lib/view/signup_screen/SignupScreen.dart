import 'package:baby_vax/shared/Components.dart';
import 'package:baby_vax/shared/ErrorHandler.dart';
import 'package:baby_vax/shared/style/Colors.dart';
import 'package:baby_vax/view/layout/Home.dart';
import 'package:baby_vax/view/login_screen/LoginScreen.dart';
import 'package:baby_vax/view/signup_screen/provider/SignupNotifier.dart';
import 'package:baby_vax/view/signup_screen/provider/SignupStates.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../login_screen/provider/LoginNotifier.dart';

class SignupScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signupState = ref.watch(signupNotifierProvider);
    final signupNotifier = ref.watch(signupNotifierProvider.notifier);
    final loginState = ref.watch(loginNotifierProvider);
    final loginNotifier = ref.watch(loginNotifierProvider.notifier);
    var emailController = TextEditingController();
    var nameController = TextEditingController();
    var passwordController = TextEditingController();
    var heightController = TextEditingController();
    var weightController = TextEditingController();
    var bloodPercentController = TextEditingController();
    var headCircleController = TextEditingController();
    var formKey = GlobalKey<FormState>();
    ref.listen<SignupStates>(signupNotifierProvider, (prev, next) {
      if (next.error != null) {
        String niceError =
            ErrorHandler.getNiceErrorMessage(next.error.toString());
        myMsg(
            context: context,
            content: niceError,
            background: Colors.black.withOpacity(.8));
      }
      if (next.success) {
        myNavigator(context, HomeLayout());
        myMsg(
            context: context,
            content: '! تم انشاء حسابك بنجاح. انتظر قليلا ',
            background: Colors.green.withOpacity(.8));
      }
    });

    return Scaffold(
        body: Center(
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
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
                    prefixIcon: Icons.email_outlined,
                    labelColor: primaryColor,
                    borderColor: primaryColor,
                    label: 'البريد الالكتروني'),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: defaultFormField(
                    controller: nameController,
                    keyboardType: TextInputType.name,
                    iconColor: primaryColor,
                    prefixIcon: Icons.person,
                    borderColor: primaryColor,
                    labelColor: primaryColor,
                    label: 'الاسم رباعي'),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: defaultButton(
                    width: double.infinity,
                    background: primaryColor,
                    radius: 20,
                    onPressed: () {
                      signupNotifier.datePicker(context);
                    },
                    child: ListTile(
                      trailing: const Icon(
                        Icons.date_range_rounded,
                        color: myWhiteColor,
                        size: 30,
                      ),
                      title: Text(
                        signupState.dateSelected
                            ? signupNotifier.selectedDateText ?? ''
                            : 'الرجاء تحديد تاريخ الولادة',
                        style: const TextStyle(
                            color: myWhiteColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w900),
                      ),
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: passwordFormField(
                    controller: passwordController,
                    isVisible: signupState.isVisible,
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
                      signupNotifier.togglePasswordIcon();
                    }),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: defaultFormField(
                          controller: bloodPercentController,
                          keyboardType: TextInputType.number,
                          label: 'نسبة دم الطفل',
                          borderColor: primaryColor,
                          labelColor: primaryColor,
                          prefixIcon: Icons.medication_liquid_sharp,
                          iconColor: primaryColor,
                        )),
                  ),
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: defaultFormField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          label: 'وزن الطفل',
                          borderColor: primaryColor,
                          labelColor: primaryColor,
                          prefixIcon: Icons.medical_services_outlined,
                          iconColor: primaryColor,
                        )),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: defaultFormField(
                          controller: headCircleController,
                          keyboardType: TextInputType.number,
                          label: 'محيط الرأس',
                          borderColor: primaryColor,
                          labelColor: primaryColor,
                          prefixIcon: Icons.account_circle_rounded,
                          iconColor: primaryColor,
                        )),
                  ),
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: defaultFormField(
                          controller: heightController,
                          keyboardType: TextInputType.number,
                          label: 'طول الطفل',
                          borderColor: primaryColor,
                          labelColor: primaryColor,
                          prefixIcon: Icons.height_sharp,
                          iconColor: primaryColor,
                        )),
                  ),
                ],
              ),
              const SizedBox(
                height: 40,
              ),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: defaultButton(
                      width: double.infinity,
                      background: primaryColor,
                      radius: 20,
                      onPressed: () {
                        if ((formKey.currentState?.validate() ?? false) &&
                            (signupNotifier.selectedDateText!.isNotEmpty)) {
                          signupNotifier.userSignup(
                              email: emailController.text,
                              password: passwordController.text,
                              name: nameController.text,
                              birthDate:
                                  signupNotifier.selectedDateText.toString(),
                              weight: int.parse(weightController.text),
                              bloodPercent:
                                  int.parse(bloodPercentController.text),
                              height: int.parse(heightController.text),
                              headCircle: int.parse(headCircleController.text));
                        }
                      },
                      child: CustomBoldText(
                          title: 'انشاء الحساب',
                          size: 22,
                          background: myWhiteColor))),
            ],
          ),
        ),
      ),
    ));
  }
}
