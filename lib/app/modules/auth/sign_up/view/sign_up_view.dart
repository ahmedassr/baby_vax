import 'package:baby_vax/app/core/widget/app_leading_icon.dart';
import 'package:baby_vax/app/core/widget/custom_app_bar.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/imports/import_manger.dart';
import '../../../../core/widget/app_logo.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDarkMode
          ? AppColors.backgroundDark
          : const Color(0xFFFDFDFC),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppConstant.buttonPadding,
          child: AppButton(
            onPressed: () => controller.userSignup(),
            text: "Sign Up",
          ),
        ),
      ),
      appBar: const CustomAppBar(),
      body: controller.obx(
        (_) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: AppConstant.columnPadding
                .copyWith(top: 0, left: 24, right: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                10.sbh,
                Center(
                  child: Column(
                    children: [
                      const AppLogo(),
                      24.sbh,
                      AppText(
                        text: "Sign Up",
                        style: AppTextStyles.headLineMedium.copyWith(
                          color: AppColors.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      4.sbh,
                      AppText(
                        text: "Create an account for your baby care journey",
                        maxLines: 2,
                        style: AppTextStyles.headLineMedium.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // FORM SECTION
                Container(
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? AppColors.backgroundDark
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.06),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppLeadingIcon(icon: Icons.info_outline),
                          8.sbw,
                          AppText(
                            text: "Baby Information",
                            style: AppTextStyles.headLineSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      22.sbh,
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
                      const SizedBox(height: 20),
                      // Password
                      Obx(() => LabeledTextField(
                            label: "Password",
                            controller: controller
                                    .signupControllers["passwordController"] ??
                                TextEditingController(),
                            obscureText: true,
                            errorText: (controller
                                        .signupErrorText["passwordErrorText"]
                                        ?.value
                                        .isNotEmpty ??
                                    false)
                                ? controller
                                    .signupErrorText["passwordErrorText"]?.value
                                : null,
                          )),
                      const SizedBox(height: 20),
                      // Full Name
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
                      const SizedBox(height: 20),
                      // Date of Birth
                      Obx(() => LabeledTextField(
                            label: "Date of Birth",
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
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? AppColors.backgroundDark
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.05),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppLeadingIcon(icon: Icons.analytics_outlined),
                          8.sbw,
                          AppText(
                            text: "Baby's Measurements",
                            style: AppTextStyles.headLineSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      22.sbh,
                      Center(
                        child: Wrap(
                          spacing: 22,
                          runSpacing: 22,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Obx(() => SizedBox(
                                  width: 130,
                                  child: LabeledTextField(
                                    label: "Weight (kg)",
                                    fontSize: 13,
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
                                  width: 130,
                                  child: LabeledTextField(
                                    label: "Height (cm)",
                                    keyboardType: TextInputType.number,
                                    fontSize: 13,
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
                                  width: 130,
                                  child: LabeledTextField(
                                    label: "Head Size (cm)",
                                    keyboardType: TextInputType.number,
                                    fontSize: 13,
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
                                            .signupErrorText[
                                                "headSizeErrorText"]
                                            ?.value
                                        : null,
                                  ),
                                )),
                            Obx(() => SizedBox(
                                  width: 130,
                                  child: LabeledTextField(
                                    label: "Blood % (g/dl)",
                                    fontSize: 13,
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
                        ),
                      ),
                    ],
                  ),
                ),
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
        },
      ),
    );
  }
}
