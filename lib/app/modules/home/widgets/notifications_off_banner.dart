import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Shown on the home screen while this app's notifications are turned off,
/// so the parent knows vaccine reminders won't appear.
class NotificationsOffBanner extends StatelessWidget {
  const NotificationsOffBanner({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('notifications_off_banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notifications_off_outlined,
                  color: colors.onErrorContainer),
              10.sbw,
              Expanded(
                child: AppText(
                  text: "Notification_permission_denied_msg".tr,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: colors.onErrorContainer),
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const Key('open_notification_settings_button'),
              onPressed: onOpenSettings,
              child: AppText(
                text: "Notification_open_settings".tr,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.onErrorContainer,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
