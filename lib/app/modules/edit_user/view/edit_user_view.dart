import 'package:baby_vax/app/core/imports/import_manger.dart';

/// The baby's profile: who, measurements, and the (read-only) account.
class EditUserView extends GetView<EditUserController> {
  const EditUserView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const TextInputType decimal =
        TextInputType.numberWithOptions(decimal: true);

    if (controller.original == null) {
      return Scaffold(
        appBar: CustomAppBar(title: "EditUserView_edit_user_title".tr),
        body: AppEmptyState(
          icon: Icons.person_off_outlined,
          title: "HomeView_no_profile_title".tr,
          actionLabel: "back_label".tr,
          onAction: Get.back,
        ),
      );
    }

    Widget measurement(Key key, String label, String unit,
            TextEditingController c, RxnString error) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Obx(() => AppField(
                key: key,
                label: label,
                optional: true,
                controller: c,
                keyboardType: decimal,
                textInputAction: TextInputAction.next,
                suffixText: unit,
                errorText: error.value,
                onChanged: (_) => error.value = null,
              )),
        );

    return Scaffold(
      appBar: CustomAppBar(title: "EditUserView_edit_user_title".tr),
      body: ListView(
        padding: AppSpacing.screenVertical,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          Obx(() => controller.saveError.value == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: AppBanner(
                      key: const Key('edit_error'),
                      tone: AppBannerTone.error,
                      message: controller.saveError.value!),
                )),
          AppSectionHeader(
              title: "Signup_step_baby".tr,
              padding: const EdgeInsets.only(bottom: AppSpacing.md)),
          Obx(() => AppField(
                key: const Key('edit_name'),
                label: "Signup_baby_name_label".tr,
                controller: controller.name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                errorText: controller.nameError.value,
                onChanged: (_) => controller.nameError.value = null,
              )),
          const SizedBox(height: AppSpacing.lg),
          Obx(() => AppField(
                key: const Key('edit_birthday'),
                label: "date_of_birth_label".tr,
                controller: controller.birthday,
                readOnly: true,
                helper: "EditUser_birthday_helper".tr,
                errorText: controller.birthdayError.value,
                onTap: () => controller.selectBirthday(context),
              )),
          const SizedBox(height: AppSpacing.lg),
          Text("Signup_sex_label".tr, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text("Signup_sex_helper".tr, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => Row(
                children: <Widget>[
                  Expanded(
                    child: AppChoiceTile(
                      key: const Key('edit_sex_female'),
                      label: "sex_female".tr,
                      icon: Icons.female_rounded,
                      selected: controller.sex.value == BabySex.female,
                      onTap: () => controller.setSex(BabySex.female),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppChoiceTile(
                      key: const Key('edit_sex_male'),
                      label: "sex_male".tr,
                      icon: Icons.male_rounded,
                      selected: controller.sex.value == BabySex.male,
                      onTap: () => controller.setSex(BabySex.male),
                    ),
                  ),
                ],
              )),
          AppSectionHeader(title: "Signup_step_measurements".tr),
          measurement(const Key('edit_weight'), "weight_label".tr, "unit_kg".tr,
              controller.weight, controller.weightError),
          measurement(const Key('edit_height'), "height_label".tr, "unit_cm".tr,
              controller.height, controller.heightError),
          measurement(const Key('edit_head'), "head_size_label".tr,
              "unit_cm".tr, controller.headSize, controller.headSizeError),
          measurement(const Key('edit_blood'), "blood_percentage_label".tr,
              "unit_g_dl".tr, controller.blood, controller.bloodError),
          AppSectionHeader(
              title: "Signup_step_account".tr,
              padding: const EdgeInsets.only(
                  top: AppSpacing.sm, bottom: AppSpacing.sm)),
          AppListGroup(children: <Widget>[
            AppListRow(
              icon: Icons.alternate_email_rounded,
              title: bidiIsolate(controller.email),
              subtitle: "EditUser_email_readonly".tr,
            ),
          ]),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Obx(() => AppButton(
                key: const Key('edit_save'),
                text: "EditUser_save".tr,
                loading: controller.isSaving.value,
                onPressed: controller.updateUser,
              )),
        ),
      ),
    );
  }
}
