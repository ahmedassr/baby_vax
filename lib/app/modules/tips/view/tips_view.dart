import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';

import '../widget/tip_card.dart';

/// Care tips, written by the Baby Vax team in the Firebase console.
class TipsView extends GetView<TipsController> {
  const TipsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return controller.obx(
      (List<TipsModel>? tips) => RefreshIndicator(
        onRefresh: controller.fetchTips,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screenVertical,
          itemCount: (tips?.length ?? 0) + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, int index) {
            if (index == 0) {
              return Text("TipsHeader_tips_hint".tr,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
            }
            final TipsModel tip = tips![index - 1];
            return TipCard(
              title: tip.title,
              description: tip.description,
              onTap: () => controller.onTipPressed(tip),
            );
          },
        ),
      ),
      onLoading: const AppLoading(),
      onError: (String? error) =>
          AppErrorState(message: error, onRetry: controller.fetchTips),
      onEmpty: AppEmptyState(
        icon: Icons.lightbulb_outline_rounded,
        title: "TipsView_empty_title".tr,
        message: "TipsView_empty_state_text".tr,
        actionLabel: "retry_label".tr,
        onAction: controller.fetchTips,
      ),
    );
  }
}
