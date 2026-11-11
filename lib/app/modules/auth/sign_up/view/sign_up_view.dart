import 'package:intl/intl.dart';

import '../../../../core/imports/import_manger.dart';
import '../../../../core/utils/validators.dart';

/// Sign-up as five short steps. See [SignupController].
class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  static String titleKey(SignupStep s) => switch (s) {
        SignupStep.account => "Signup_step_account",
        SignupStep.baby => "Signup_step_baby",
        SignupStep.measurements => "Signup_step_measurements",
        SignupStep.reminders => "Signup_step_reminders",
        SignupStep.summary => "Signup_step_summary",
      };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // System back walks the steps backwards before leaving the screen.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        if (!controller.back()) Get.back();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          onBackPressed: () {
            if (!controller.back()) Get.back();
          },
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: AppSpacing.screen,
                child: Obx(() => AppStepHeader(
                      current: controller.stepIndex,
                      total: SignupStep.values.length,
                      title: titleKey(controller.step.value).tr,
                    )),
              ),
              Expanded(
                child: Obx(() => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: SingleChildScrollView(
                        key: ValueKey<SignupStep>(controller.step.value),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                            AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl),
                        child: _stepBody(context, controller.step.value),
                      ),
                    )),
              ),
              _BottomBar(controller: controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody(BuildContext context, SignupStep s) => switch (s) {
        SignupStep.account => _AccountStep(controller: controller),
        SignupStep.baby => _BabyStep(controller: controller),
        SignupStep.measurements => _MeasurementsStep(controller: controller),
        SignupStep.reminders => _RemindersStep(controller: controller),
        SignupStep.summary => _SummaryStep(controller: controller),
      };
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Obx(() {
          final SignupStep s = controller.step.value;
          final bool asking = s == SignupStep.reminders &&
              controller.reminders.value == ReminderPermission.notAsked;
          return Row(
            children: <Widget>[
              if (!controller.isFirstStep) ...<Widget>[
                Expanded(
                  child: AppButton(
                    key: const Key('signup_back'),
                    text: "back_label".tr,
                    variant: AppButtonVariant.outline,
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () => controller.back(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                flex: 2,
                child: asking
                    ? AppButton(
                        key: const Key('signup_turn_on_reminders'),
                        text: "Signup_reminders_turn_on".tr,
                        icon: Icons.notifications_active_outlined,
                        loading: controller.isRequestingPermission.value,
                        onPressed: controller.askForReminders,
                      )
                    : AppButton(
                        key: const Key('signup_next'),
                        text: controller.isLastStep
                            ? "Signup_create_account".tr
                            : "next_label".tr,
                        loading: controller.isSubmitting.value,
                        onPressed: controller.next,
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Intro(text: "Signup_step_account_hint".tr),
          Obx(() => AppField(
                key: const Key('signup_email'),
                label: "email_label".tr,
                controller: controller.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.email],
                errorText: controller.emailError.value,
                onChanged: (_) => controller.emailError.value = null,
              )),
          const SizedBox(height: AppSpacing.lg),
          Obx(() => AppField(
                key: const Key('signup_password'),
                label: "password_label".tr,
                controller: controller.password,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.newPassword],
                helper: "Signup_password_helper".trParams(
                    <String, String>{'min': '${Validators.minPasswordLength}'}),
                errorText: controller.passwordError.value,
                onChanged: (_) => controller.passwordError.value = null,
                onSubmitted: (_) => controller.next(),
              )),
        ],
      ),
    );
  }
}

class _BabyStep extends StatelessWidget {
  const _BabyStep({required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Intro(text: "Signup_step_baby_hint".tr),
        Obx(() => AppField(
              key: const Key('signup_name'),
              label: "Signup_baby_name_label".tr,
              controller: controller.name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              errorText: controller.nameError.value,
              onChanged: (_) => controller.nameError.value = null,
            )),
        const SizedBox(height: AppSpacing.lg),
        Obx(() => AppField(
              key: const Key('signup_birthday'),
              label: "date_of_birth_label".tr,
              controller: controller.birthday,
              readOnly: true,
              hint: "Signup_birthday_hint".tr,
              helper: "Signup_birthday_helper".tr,
              errorText: controller.birthdayError.value,
              onTap: () => controller.selectBirthday(context),
            )),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text("Signup_sex_label".tr, style: theme.textTheme.titleSmall),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text("Signup_sex_helper".tr, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Obx(() => Row(
              children: <Widget>[
                Expanded(
                  child: _ChoiceTile(
                    key: const Key('signup_sex_female'),
                    label: "sex_female".tr,
                    icon: Icons.female_rounded,
                    selected: controller.sex.value == BabySex.female,
                    onTap: () => controller.setSex(BabySex.female),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ChoiceTile(
                    key: const Key('signup_sex_male'),
                    label: "sex_male".tr,
                    icon: Icons.male_rounded,
                    selected: controller.sex.value == BabySex.male,
                    onTap: () => controller.setSex(BabySex.male),
                  ),
                ),
              ],
            )),
        Obx(() => controller.sexError.value == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsetsDirectional.only(
                    top: AppSpacing.xs, start: AppSpacing.xxs),
                child: Text(controller.sexError.value!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error)),
              )),
      ],
    );
  }
}

class _MeasurementsStep extends StatelessWidget {
  const _MeasurementsStep({required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    const TextInputType decimal =
        TextInputType.numberWithOptions(decimal: true);
    Widget field(Key key, String label, String unit, TextEditingController c,
            RxnString error, TextInputAction action) =>
        Obx(() => AppField(
              key: key,
              label: label,
              optional: true,
              controller: c,
              keyboardType: decimal,
              textInputAction: action,
              suffixText: unit,
              errorText: error.value,
              onChanged: (_) => error.value = null,
            ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Intro(text: "Signup_step_measurements_hint".tr),
        field(const Key('signup_weight'), "weight_label".tr, "unit_kg".tr,
            controller.weight, controller.weightError, TextInputAction.next),
        const SizedBox(height: AppSpacing.lg),
        field(const Key('signup_height'), "height_label".tr, "unit_cm".tr,
            controller.height, controller.heightError, TextInputAction.next),
        const SizedBox(height: AppSpacing.lg),
        field(
            const Key('signup_head'),
            "head_size_label".tr,
            "unit_cm".tr,
            controller.headSize,
            controller.headSizeError,
            TextInputAction.next),
        const SizedBox(height: AppSpacing.lg),
        field(
            const Key('signup_blood'),
            "blood_percentage_label".tr,
            "unit_g_dl".tr,
            controller.blood,
            controller.bloodError,
            TextInputAction.done),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: const Key('signup_skip_measurements'),
            onPressed: controller.skipMeasurements,
            child: Text("Signup_skip_for_now".tr),
          ),
        ),
      ],
    );
  }
}

class _RemindersStep extends StatelessWidget {
  const _RemindersStep({required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String locale = AppDateFormat.currentLocale;
    String hour(int h) => (DateFormat.jm(locale)..useNativeDigits = false)
        .format(DateTime(2000, 1, 1, h));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Center(
          child:
              AppIconBadge(icon: Icons.notifications_active_rounded, size: 88),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text("Signup_reminders_title".tr,
            style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
        Text(
          "Signup_reminders_body".trIsolated(<String, String>{
            'evening': hour(AppConstant.eveningReminderHour),
            'morning': hour(AppConstant.morningReminderHour),
          }),
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        Obx(() => switch (controller.reminders.value) {
              ReminderPermission.notAsked => AppBanner(
                  message: "Signup_reminders_why".tr,
                  icon: Icons.lock_outline_rounded,
                ),
              ReminderPermission.granted => AppBanner(
                  key: const Key('signup_reminders_on'),
                  message: "Signup_reminders_granted".tr,
                  tone: AppBannerTone.success,
                ),
              ReminderPermission.denied => AppBanner(
                  key: const Key('signup_reminders_off'),
                  message: "Signup_reminders_denied".tr,
                  tone: AppBannerTone.warning,
                ),
            }),
        Obx(() => controller.reminders.value == ReminderPermission.notAsked
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Center(
                  child: TextButton(
                    key: const Key('signup_reminders_not_now'),
                    onPressed: () {
                      controller.reminders.value = ReminderPermission.denied;
                      controller.next();
                    },
                    child: Text("Signup_reminders_not_now".tr),
                  ),
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    String orNot(String v, String unit) => v.trim().isEmpty
        ? "not_recorded_label".tr
        : '${SignupController.normalised(v)} $unit';
    final String? sex = controller.sex.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Intro(text: "Signup_step_summary_hint".tr),
        Obx(() => controller.submitError.value == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: AppBanner(
                  key: const Key('signup_submit_error'),
                  message: controller.submitError.value!,
                  tone: AppBannerTone.error,
                ),
              )),
        _SummaryCard(
          title: "Signup_step_account".tr,
          onEdit: () => controller.goTo(SignupStep.account),
          rows: <(String, String)>[
            ("email_label".tr, bidiIsolate(controller.email.text.trim())),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SummaryCard(
          title: "Signup_step_baby".tr,
          onEdit: () => controller.goTo(SignupStep.baby),
          rows: <(String, String)>[
            (
              "Signup_baby_name_label".tr,
              bidiIsolate(controller.name.text.trim())
            ),
            ("date_of_birth_label".tr, controller.birthday.text),
            (
              "Signup_sex_label".tr,
              sex == BabySex.female
                  ? "sex_female".tr
                  : sex == BabySex.male
                      ? "sex_male".tr
                      : "not_recorded_label".tr
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SummaryCard(
          title: "Signup_step_measurements".tr,
          onEdit: () => controller.goTo(SignupStep.measurements),
          rows: <(String, String)>[
            ("weight_label".tr, orNot(controller.weight.text, "unit_kg".tr)),
            ("height_label".tr, orNot(controller.height.text, "unit_cm".tr)),
            (
              "head_size_label".tr,
              orNot(controller.headSize.text, "unit_cm".tr)
            ),
            (
              "blood_percentage_label".tr,
              orNot(controller.blood.text, "unit_g_dl".tr)
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SummaryCard(
          title: "Signup_step_reminders".tr,
          onEdit: () => controller.goTo(SignupStep.reminders),
          rows: <(String, String)>[
            (
              "Signup_step_reminders".tr,
              controller.reminders.value == ReminderPermission.granted
                  ? "reminders_on_label".tr
                  : "reminders_off_label".tr
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text("Signup_schedule_note".tr, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        // Shown where the schedule is created, so the parent sees it before
        // relying on any date.
        const MedicalDisclaimer(),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.rows,
    required this.onEdit,
  });

  final String title;
  final List<(String, String)> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.lg,
          end: AppSpacing.xs,
          top: AppSpacing.xs,
          bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleSmall),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text("edit_label".tr,
                    semanticsLabel: "edit_section_label"
                        .trParams(<String, String>{'section': title})),
              ),
            ],
          ),
          for (final (String label, String value) in rows)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  end: AppSpacing.md, top: AppSpacing.xs),
              child: MergeSemantics(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    Text('$label:', style: theme.textTheme.bodySmall),
                    Text(value, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One option in a two-way choice, at least 56dp tall, announced as a
/// selected/unselected button in a group.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(label,
                        style: theme.textTheme.titleSmall?.copyWith(
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurface)),
                  ),
                  if (selected) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.check_rounded,
                        size: 18, color: scheme.onPrimaryContainer),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Text(text,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}
