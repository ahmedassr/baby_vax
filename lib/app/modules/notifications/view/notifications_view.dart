import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/notification/application/notification_feed.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/home/widgets/notifications_off_banner.dart';

import '../controller/notifications_controller.dart';

/// The app's reminders as a list: Today, Upcoming, Earlier. Built on the
/// phone from the vaccine and custom reminders it schedules; tapping one
/// opens its dose or reminder.
class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  static String _childName() {
    final String n = Get.isRegistered<HomeController>()
        ? (Get.find<HomeController>().userDetails.value?.name ?? '').trim()
        : '';
    return n.isEmpty ? "Notification_child_fallback".tr : n;
  }

  /// The title and body the phone shows for [i].
  static (String, String) texts(FeedItem i) {
    switch (i.kind) {
      case FeedKind.vaccineEve:
      case FeedKind.vaccineDay:
        final bool eve = i.kind == FeedKind.vaccineEve;
        return (
          (eve
                  ? 'Notification_vaccine_tomorrow_title'
                  : 'Notification_vaccine_today_title')
              .tr,
          (eve
                  ? 'Notification_vaccine_tomorrow_body'
                  : 'Notification_vaccine_today_body')
              .trIsolated(<String, String>{
            'child': _childName(),
            'vaccine': i.dose!.displayName,
          }),
        );
      case FeedKind.custom:
        final String note = (i.reminder!.note ?? '').trim();
        return (
          bidiIsolate(i.reminder!.title),
          note.isEmpty ? 'Reminder_custom_default_body'.tr : bidiIsolate(note),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Notifications_title".tr),
      body: Obx(() {
        if (controller.isLoading.value) return const AppLoading();
        final DateTime now = controller.now;
        final int unread = controller.unreadCount;
        final List<Widget> sections = <Widget>[
          for (final FeedSection s in FeedSection.values)
            if (controller.section(s).isNotEmpty) ...<Widget>[
              AppSectionHeader(
                  key: Key('notifications_section_${s.name}'),
                  title: "Notifications_section_${s.name}".tr),
              for (final FeedItem i in controller.section(s)) ...<Widget>[
                _NotificationRow(
                  key: Key('notification_${i.key}'),
                  item: i,
                  now: now,
                  unread: controller.isUnread(i),
                  onTap: () => controller.open(i),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
        ];
        return RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
            children: <Widget>[
              if (controller.notificationsOff.value) ...<Widget>[
                NotificationsOffBanner(onOpenSettings: controller.openSettings),
                const SizedBox(height: AppSpacing.md),
              ],
              if (unread > 0)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    key: const Key('notifications_mark_all'),
                    onPressed: controller.markAllRead,
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text("Notifications_mark_all".tr),
                  ),
                ),
              if (sections.isEmpty)
                AppEmptyState(
                  key: const Key('notifications_empty'),
                  scrollable: false,
                  icon: Icons.notifications_none_rounded,
                  title: "Notifications_empty_title".tr,
                  message: "Notifications_empty_body".tr,
                )
              else
                ...sections,
            ],
          ),
        );
      }),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    super.key,
    required this.item,
    required this.now,
    required this.unread,
    required this.onTap,
  });

  final FeedItem item;
  final DateTime now;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final (String title, String body) = NotificationsView.texts(item);
    final bool delivered = item.deliveredBy(now);
    final String when = item.sectionAt(now) == FeedSection.today
        ? AppDateFormat.time(item.at)
        : AppDateFormat.dateTime(item.at);
    final String status = !delivered
        ? "Notifications_scheduled".tr
        : unread
            ? "Notifications_unread".tr
            : "";
    return AppCard(
      onTap: onTap,
      semanticLabel: <String>[
        if (status.isNotEmpty) status,
        title,
        body,
        when,
      ].join(', '),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIconBadge(
            icon: item.kind == FeedKind.custom
                ? Icons.alarm_rounded
                : Icons.vaccines_rounded,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: unread
                        ? theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)
                        : theme.textTheme.titleSmall),
                Text(body,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(when,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    if (!delivered)
                      Text("Notifications_scheduled".tr,
                          key: const Key('notification_scheduled'),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.primary)),
                  ],
                ),
              ],
            ),
          ),
          if (unread)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
              child: Container(
                key: const Key('notification_unread_dot'),
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                decoration: BoxDecoration(
                    color: scheme.primary, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
