import 'package:baby_vax/app/core/widget/custom_app_bar.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/imports/import_manger.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: AppConstant.buttonPadding,
        child: AppButton(
            onPressed: () => controller.userSignup(), text: "Sign Up"),
      ),
      appBar: const CustomAppBar(),
      body: controller.obx(
          (_) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: AppConstant.columnPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      45.sbh,
                      Center(
                        child: AppText(
                          text: "Sign Up",
                          style: AppTextStyles.headLineMedium
                              .copyWith(color: AppColors.primary, fontSize: 30),
                        ),
                      ),
                      50.sbh,
                      Obx(() => LabeledTextField(
                            label: "Email",
                            controller: controller
                                    .signupControllers["emailController"] ??
                                TextEditingController(),
                            keyboardType: TextInputType.emailAddress,
                            errorText: (controller
                                        .signupErrorText["emailErrorText"]
                                        ?.value
                                        .isNotEmpty ??
                                    false)
                                ? controller
                                    .signupErrorText["emailErrorText"]?.value
                                : null,
                          )),
                      10.sbh,
                      Obx(() => LabeledTextField(
                            label: "password",
                            controller: controller
                                    .signupControllers["passwordController"] ??
                                TextEditingController(),
                            errorText: (controller
                                        .signupErrorText["passwordErrorText"]
                                        ?.value
                                        .isNotEmpty ??
                                    false)
                                ? controller
                                    .signupErrorText["passwordErrorText"]?.value
                                : null,
                          )),
                      10.sbh,
                      Obx(() => LabeledTextField(
                            label: "Full Name",
                            controller: controller
                                    .signupControllers["nameController"] ??
                                TextEditingController(),
                            errorText: (controller
                                        .signupErrorText["nameErrorText"]
                                        ?.value
                                        .isNotEmpty ??
                                    false)
                                ? controller
                                    .signupErrorText["nameErrorText"]?.value
                                : null,
                          )),
                      10.sbh,
                      Obx(() => LabeledTextField(
                            label: "Date of birth",
                            keyboardType: TextInputType.datetime,
                            controller: controller
                                    .signupControllers["birthdayController"] ??
                                TextEditingController(),
                            readOnly: true,
                            onTap: controller.selectBirthday,
                            errorText: (controller
                                        .signupErrorText["birthdayErrorText"]
                                        ?.value
                                        .isNotEmpty ??
                                    false)
                                ? controller
                                    .signupErrorText["birthdayErrorText"]?.value
                                : null,
                          )),
                      20.sbh,
                      AppText(
                        text: "Baby's Measurements :",
                        style: AppTextStyles.headLineSmall.copyWith(
                            color: context.isDarkMode
                                ? AppColors.backgroundLight
                                : AppColors.primary),
                      ),
                      20.sbh,
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Obx(() => SizedBox(
                                width: 110,
                                child: LabeledTextField(
                                  label: "Weight",
                                  keyboardType: TextInputType.number,
                                  controller: controller.signupControllers[
                                          "weightController"] ??
                                      TextEditingController(),
                                  errorText: (controller
                                              .signupErrorText[
                                                  "weightErrorText"]
                                              ?.value
                                              .isNotEmpty ??
                                          false)
                                      ? controller
                                          .signupErrorText["weightErrorText"]
                                          ?.value
                                      : null,
                                ),
                              )),
                          Obx(() => SizedBox(
                                width: 110,
                                child: LabeledTextField(
                                  label: "Height",
                                  keyboardType: TextInputType.number,
                                  controller: controller.signupControllers[
                                          "heightController"] ??
                                      TextEditingController(),
                                  errorText: (controller
                                              .signupErrorText[
                                                  "heightErrorText"]
                                              ?.value
                                              .isNotEmpty ??
                                          false)
                                      ? controller
                                          .signupErrorText["heightErrorText"]
                                          ?.value
                                      : null,
                                ),
                              )),
                          Obx(() => SizedBox(
                                width: 110,
                                child: LabeledTextField(
                                  label: "Head Size",
                                  keyboardType: TextInputType.number,
                                  controller: controller.signupControllers[
                                          "headSizeController"] ??
                                      TextEditingController(),
                                  errorText: (controller
                                              .signupErrorText[
                                                  "headSizeErrorText"]
                                              ?.value
                                              .isNotEmpty ??
                                          false)
                                      ? controller
                                          .signupErrorText["headSizeErrorText"]
                                          ?.value
                                      : null,
                                ),
                              )),
                          Obx(() => SizedBox(
                                width: 110,
                                child: LabeledTextField(
                                  label: "Blood Percentage",
                                  keyboardType: TextInputType.number,
                                  controller: controller.signupControllers[
                                          "bloodPercentageController"] ??
                                      TextEditingController(),
                                  errorText: (controller
                                              .signupErrorText[
                                                  "bloodPercentageErrorText"]
                                              ?.value
                                              .isNotEmpty ??
                                          false)
                                      ? controller
                                          .signupErrorText[
                                              "bloodPercentageErrorText"]
                                          ?.value
                                      : null,
                                ),
                              )),
                        ],
                      )
                    ],
                  ),
                ),
              ),
          onLoading: const Center(child: CupertinoActivityIndicator()),
          onError: (error) {
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
