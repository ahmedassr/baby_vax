import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/utils/app_alert/alert_type_enum.dart';

/// The app's alert dialog, drawn from the theme.
///
/// v1.0 stacked up to three full-width filled buttons (all the same style,
/// so "Cancel" looked as important as "Yes") and coloured the title by
/// reading `Get.context?.isDarkMode`. Now: an icon for the alert type, the
/// title, the message, and Material dialog actions — the confirming action
/// filled, the others as text buttons.
class AlertWidget extends StatelessWidget {
  final AlertModel alert;

  const AlertWidget({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final (IconData? icon, Color color) = switch (alert.type) {
      AlertType.error || AlertType.fieldRequired => (
          Icons.error_outline_rounded,
          scheme.error
        ),
      AlertType.success => (Icons.check_circle_outline_rounded, scheme.primary),
      AlertType.attention => (Icons.help_outline_rounded, scheme.secondary),
      _ => (null, scheme.primary),
    };

    return AlertDialog(
      icon: icon == null ? null : Icon(icon, color: color, size: 32),
      title: (alert.title == null || alert.title!.isEmpty)
          ? null
          : Text(alert.title!, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (alert.imagePath != null) ...<Widget>[
              Image.asset(alert.imagePath!),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(alert.message ?? "",
                style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: <Widget>[
        if (alert.noAction != null)
          TextButton(
            key: const Key('alert_no'),
            onPressed: () {
              Get.back();
              alert.noAction?.call();
            },
            child: Text(alert.noButtonText ?? "cancel".tr),
          ),
        if (alert.additionalAction != null)
          TextButton(
            onPressed: () {
              Get.back();
              alert.additionalAction?.call();
            },
            child: Text(alert.additionalButtonText ?? "cancel".tr),
          ),
        FilledButton(
          key: const Key('alert_yes'),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            minimumSize: const Size(88, AppSpacing.minTouchTarget),
          ),
          onPressed: () {
            Get.back();
            alert.yesAction?.call();
          },
          child: Text(alert.yesButtonText ?? "ok_label".tr),
        ),
      ],
    );
  }
}
