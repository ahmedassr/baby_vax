import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/app_logo.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      bottomNavigationBar: SafeArea(
        minimum: AppConstant.buttonPadding,
        child: AppButton(
          onPressed: () => controller.userLogin(),
          text: "LoginView_login_title".tr,
        ),
      ),
      body: controller.obx(
        (_) => GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  64.sbh,
                  Center(
                    child: Column(
                      children: [
                        const AppLogo(),
                        24.sbh,
                        AppText(
                          text: "Welcome Back",
                          style: AppTextStyles.headLineMedium.copyWith(
                            color: AppColors.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        4.sbh,
                        AppText(
                          text: "LoginView_login_hint".tr,
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
                  Obx(() => LabeledTextField(
                        label: "email_label".tr,
                        controller: controller.loginController["email"] ??
                            TextEditingController(),
                        keyboardType: TextInputType.emailAddress,
                        errorText: controller.emailErrorText.value.isNotEmpty
                            ? controller.emailErrorText.value
                            : null,
                        borderRadius: 18,
                        labelStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                  24.sbh,
                  Obx(() => LabeledTextField(
                        label: "password_label".tr,
                        controller: controller.loginController["password"] ??
                            TextEditingController(),
                        errorText: controller.passwordErrorText.value.isNotEmpty
                            ? controller.passwordErrorText.value
                            : null,
                        obscureText: true,
                        borderRadius: 18,
                        labelStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                  16.sbh,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Get.toNamed(AppRoutes.signup),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: AppText(
                            text: "LoginView_create_new_account".tr,
                            style: AppTextStyles.headLineSmall.copyWith(
                              fontSize: 18,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  24.sbh,
                ],
              ),
            ),
          ),
        ),
        onLoading: const Center(
          child: CupertinoActivityIndicator(),
        ),
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
