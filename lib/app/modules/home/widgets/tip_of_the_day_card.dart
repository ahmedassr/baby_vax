import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import 'package:baby_vax/app/modules/tips/model/tip_of_the_day.dart';

/// "Tip of the day" on Home, with "See all tips" (phone review R5b: Tips
/// is no longer a tab).
///
/// One tip a day from the tips already loaded (see [TipOfTheDay]); tapping
/// it opens the usual tip details. Nothing is shown while the tips load or
/// when there are none, so Home never waits on them.
class TipOfTheDayCard extends StatelessWidget {
  const TipOfTheDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TipsController>()) return const SizedBox.shrink();
    final TipsController tips = Get.find<TipsController>();
    const Widget nothing = SizedBox.shrink();
    return tips.obx(
      (List<TipsModel>? list) {
        final DateTime now = Get.isRegistered<HomeController>()
            ? Get.find<HomeController>().now
            : DateTime.now();
        final TipsModel? tip = TipOfTheDay.pick(list ?? <TipsModel>[], now);
        if (tip == null) return nothing;
        return _Card(
            tip: tip,
            onOpen: () => tips.onTipPressed(tip),
            onSeeAll: tips.openAll);
      },
      onLoading: nothing,
      onEmpty: nothing,
      onError: (_) => nothing,
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(
      {required this.tip, required this.onOpen, required this.onSeeAll});

  final TipsModel tip;
  final VoidCallback onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: "Home_tip_of_day".tr,
          actionLabel: "Home_see_all_tips".tr,
          onAction: onSeeAll,
        ),
        AppCard(
          key: const Key('home_tip_of_day'),
          onTap: onOpen,
          semanticLabel:
              '${"Home_tip_of_day".tr}. ${tip.title}. ${tip.description}',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIconBadge(
                icon: Icons.lightbulb_outline_rounded,
                background: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(bidiIsolate(tip.title),
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xs),
                    Text(bidiIsolate(tip.description),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
