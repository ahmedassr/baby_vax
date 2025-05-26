import 'package:baby_vax/app/config/constant/app_constant.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter/cupertino.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child:
            AppButton(onPressed: () => controller.userLogin(), text: "Login"),
      ),
      body: controller.obx(
          (_) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      110.sbh,
                      Center(
                        child: AppText(
                          text: "Login Now",
                          style: AppTextStyles.headLineMedium
                              .copyWith(color: AppColors.primary, fontSize: 30),
                        ),
                      ),
                      50.sbh,
                      Obx(() => LabeledTextField(
                            label: "Email",
                            controller: controller.loginController["email"] ??
                                TextEditingController(),
                            keyboardType: TextInputType.emailAddress,
                            errorText:
                                controller.emailErrorText.value.isNotEmpty
                                    ? controller.emailErrorText.value
                                    : null,
                          )),
                      20.sbh,
                      Obx(() => LabeledTextField(
                            label: "password",
                            controller:
                                controller.loginController["password"] ??
                                    TextEditingController(),
                            errorText:
                                controller.passwordErrorText.value.isNotEmpty
                                    ? controller.passwordErrorText.value
                                    : null,
                          )),
                      20.sbh,
                      AppText(
                        text: "Create New Account",
                        style: AppTextStyles.headLineSmall.copyWith(
                            fontSize: 16,
                            color: context.isDarkMode
                                ? AppColors.backgroundLight
                                : AppColors.backgroundDark),
                      ),
                    ],
                  ),
                ),
              ),
          onLoading: const Center(
            child: CupertinoActivityIndicator(),
          ), onError: (error) {
        if (error != null && error.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppConstant.alertService.showError(message: error);
            controller.setSuccess();
          });
        }
        return const SizedBox.shrink();
      }),
    );
  }
}
