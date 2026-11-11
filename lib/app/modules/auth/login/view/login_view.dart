import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/app_logo.dart';

/// Sign-in. The form stays on screen whatever happens: field problems show
/// under the field, server problems in a banner above the form.
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          // Tapping outside the fields hides the keyboard. Not a control,
          // so it is kept out of the accessibility tree.
          excludeFromSemantics: true,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  const Center(child: AppLogo(size: 72)),
                  const SizedBox(height: AppSpacing.xl),
                  Semantics(
                    header: true,
                    child: Text("LoginView_welcome_back".tr,
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text("LoginView_login_hint".tr,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xxl),
                  Obx(() => controller.authError.value == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: AppBanner(
                            key: const Key('login_error'),
                            message: controller.authError.value!,
                            tone: AppBannerTone.error,
                          ),
                        )),
                  Obx(() => AppField(
                        key: const Key('login_email'),
                        label: "email_label".tr,
                        controller: controller.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.email],
                        errorText: controller.emailError.value,
                        onChanged: controller.onEmailChanged,
                      )),
                  const SizedBox(height: AppSpacing.lg),
                  Obx(() => AppField(
                        key: const Key('login_password'),
                        label: "password_label".tr,
                        controller: controller.password,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const <String>[AutofillHints.password],
                        errorText: controller.passwordError.value,
                        onChanged: controller.onPasswordChanged,
                        onSubmitted: (_) => controller.userLogin(),
                      )),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      key: const Key('login_forgot'),
                      onPressed: controller.openForgotPassword,
                      child: Text("LoginView_forgot_password".tr),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Obx(() => AppButton(
                        key: const Key('login_submit'),
                        text: "LoginView_login_title".tr,
                        loading: controller.isSubmitting.value,
                        onPressed: controller.userLogin,
                      )),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: <Widget>[
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        child: Text("LoginView_no_account".tr,
                            style: theme.textTheme.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    key: const Key('login_signup'),
                    text: "LoginView_create_new_account".tr,
                    variant: AppButtonVariant.outline,
                    onPressed: controller.openSignup,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
