import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Shown on the home screen while this app's notifications are turned off,
/// so the parent knows vaccine reminders won't appear.
class NotificationsOffBanner extends StatelessWidget {
  const NotificationsOffBanner({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return AppBanner(
      key: const Key('notifications_off_banner'),
      tone: AppBannerTone.warning,
      icon: Icons.notifications_off_outlined,
      message: "Notification_permission_denied_msg".tr,
      actionLabel: "Notification_open_settings".tr,
      actionKey: const Key('open_notification_settings_button'),
      onAction: onOpenSettings,
    );
  }
}
