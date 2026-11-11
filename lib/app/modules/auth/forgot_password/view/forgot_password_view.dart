import '../../../../core/imports/import_manger.dart';
import '../controller/forgot_password_controller.dart';

/// "Reset your password": one field, one action, then "check your inbox".
class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SafeArea(
        child: Obx(() => AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: controller.sentTo.value == null
                  ? _form(theme)
                  : _sent(theme, controller.sentTo.value!),
            )),
      ),
    );
  }

  Widget _form(ThemeData theme) {
    return SingleChildScrollView(
      key: const ValueKey<String>('form'),
      padding: AppSpacing.screenVertical,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppIconBadge(icon: Icons.lock_reset_rounded, size: 56),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text("ForgotPassword_title".tr,
                style: theme.textTheme.headlineMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text("ForgotPassword_hint".tr,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xxl),
          Obx(() => controller.sendError.value == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: AppBanner(
                      message: controller.sendError.value!,
                      tone: AppBannerTone.error),
                )),
          Obx(() => AppField(
                key: const Key('reset_email'),
                label: "email_label".tr,
                controller: controller.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                autofillHints: const <String>[AutofillHints.email],
                errorText: controller.emailError.value,
                onChanged: controller.onEmailChanged,
                onSubmitted: (_) => controller.send(),
              )),
          const SizedBox(height: AppSpacing.xxl),
          Obx(() => AppButton(
                key: const Key('reset_send'),
                text: "ForgotPassword_send".tr,
                loading: controller.isSending.value,
                onPressed: controller.send,
              )),
        ],
      ),
    );
  }

  Widget _sent(ThemeData theme, String address) {
    return AppEmptyState(
      key: const ValueKey<String>('sent'),
      icon: Icons.mark_email_read_outlined,
      title: "ForgotPassword_sent_title".tr,
      message: "ForgotPassword_sent_body".trIsolated({'email': address}),
      actionLabel: "ForgotPassword_back_to_login".tr,
      onAction: Get.back,
    );
  }
}
