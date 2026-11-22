import 'package:baby_vax/app/core/imports/import_manger.dart';

import '../controller/notifications_controller.dart';

/// The bell in the main tabs' app bar, with the number of delivered
/// reminders not yet read.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationsController>()) {
      return const SizedBox.shrink();
    }
    final NotificationsController c = Get.find<NotificationsController>();
    return Obx(() {
      final int n = c.unreadCount;
      return IconButton(
        key: const Key('notification_bell'),
        tooltip: n == 0
            ? "Notifications_title".tr
            : "Notifications_bell_unread".trParams(<String, String>{'n': '$n'}),
        onPressed: () {
          c.reload();
          Get.toNamed(AppRoutes.notifications);
        },
        icon: Badge(
          key: const Key('notification_badge'),
          isLabelVisible: n > 0,
          label: Text(n > 9 ? '9+' : '$n'),
          child: Icon(n > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_rounded),
        ),
      );
    });
  }
}
