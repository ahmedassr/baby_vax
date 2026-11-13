import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/schedule_summary.dart';

/// The whole schedule: a progress summary, a status filter, and the doses
/// grouped under sticky age headings (At birth, 2 months, 4 months, …).
class MedicalDatesView extends GetView<MedicalDatesController> {
  const MedicalDatesView({super.key});

  @override
  Widget build(BuildContext context) {
    return controller.obx(
      (_) => RefreshIndicator(
        onRefresh: () async => controller.fetchMedicalDates(),
        child: Obx(() => _list(context)),
      ),
      onLoading: const AppLoading(itemCount: 5),
      onError: (String? error) => AppErrorState(
        message: error,
        onRetry: controller.fetchMedicalDates,
      ),
      onEmpty: AppEmptyState(
        icon: Icons.event_busy_rounded,
        title: "Schedule_empty_title".tr,
        message: "Schedule_empty_body".tr,
        actionLabel: "retry_label".tr,
        onAction: controller.fetchMedicalDates,
      ),
    );
  }

  Widget _list(BuildContext context) {
    final ScheduleSummary summary = controller.summary;
    final List<AgeGroup> groups = controller.groups;
    final DateTime now = controller.now;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          sliver: SliverList.list(children: <Widget>[
            _Summary(summary: summary),
            const SizedBox(height: AppSpacing.md),
            const MedicalDisclaimer(compact: true),
            const SizedBox(height: AppSpacing.md),
          ]),
        ),
        SliverToBoxAdapter(
          child: _Filters(
            selected: controller.filter.value,
            summary: summary,
            onSelected: controller.setFilter,
          ),
        ),
        if (groups.isEmpty)
          SliverToBoxAdapter(
            child: AppEmptyState(
              scrollable: false,
              icon: Icons.filter_alt_off_rounded,
              title: "Schedule_empty_filter_title".tr,
              message: "Schedule_empty_filter_body".tr,
              actionLabel: "Schedule_filter_all".tr,
              onAction: () => controller.setFilter(null),
            ),
          ),
        for (final AgeGroup group in groups)
          SliverMainAxisGroup(slivers: <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: _AgeHeader(group.label),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList.separated(
                itemCount: group.doses.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, int i) {
                  final MedicalDatesModel dose = group.doses[i];
                  return AppDoseTile(
                    dose: dose,
                    now: now,
                    onTap: () => controller.onMedicalDatePressed(dose),
                  );
                },
              ),
            ),
          ]),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final ScheduleSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: <Widget>[
          AppProgressRing(
              done: summary.completed, total: summary.countable, size: 64),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("HomeView_progress_title".tr,
                    style: theme.textTheme.titleMedium),
                Text(
                  "HomeView_progress_body".trParams(<String, String>{
                    'done': '${summary.completed}',
                    'total': '${summary.countable}',
                  }),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// All / Pending / Overdue / Completed / Skipped, each with its count.
class _Filters extends StatelessWidget {
  const _Filters({
    required this.selected,
    required this.summary,
    required this.onSelected,
  });

  final DoseDisplayStatus? selected;
  final ScheduleSummary summary;
  final ValueChanged<DoseDisplayStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<(DoseDisplayStatus?, String, int)> options =
        <(DoseDisplayStatus?, String, int)>[
      (null, "Schedule_filter_all".tr, summary.total),
      for (final DoseDisplayStatus s in <DoseDisplayStatus>[
        DoseDisplayStatus.pending,
        DoseDisplayStatus.overdue,
        DoseDisplayStatus.completed,
        DoseDisplayStatus.skipped,
      ])
        (s, s.translationKey.tr, summary.filtered(s).length),
    ];
    return Semantics(
      label: "Schedule_filter_label".tr,
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            for (final (DoseDisplayStatus? s, String label, int count)
                in options) ...<Widget>[
              ChoiceChip(
                key: Key('filter_${s?.name ?? 'all'}'),
                label: Text('$label · $count'),
                selected: selected == s,
                showCheckmark: false,
                avatar:
                    s == null ? null : Icon(AppStatusChip.iconFor(s), size: 16),
                onSelected: (_) => onSelected(s),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

/// A sticky age heading. Pinned within its own group, so the heading of
/// the group being read stays at the top while scrolling.
class _AgeHeader extends SliverPersistentHeaderDelegate {
  _AgeHeader(this.label);

  final String label;

  static const double _height = 48;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final ThemeData theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: theme.textTheme.titleSmall
              ?.copyWith(color: theme.colorScheme.primary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_AgeHeader old) => old.label != label;
}
