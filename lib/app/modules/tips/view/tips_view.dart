import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import '../widget/tip_card.dart';
import '../widget/tips_header.dart';

class TipsView extends GetView<TipsController> {
  const TipsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get.lazyPut<TipsController>(() => TipsController())
    return controller.obx(
      (tips) {
        if (tips == null || tips.isEmpty) {
          return const AppEmptyState(
            message: "No tips available yet. Check back later!",
            animationPath: AppAnimations.noRecords,
          );
        }

        return RefreshableListBuilder(
          onRefresh: () => controller.fetchTips(),
          itemCount: tips.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const TipsHeader();
            }
            final tip = tips[index];
            return TipCard(
              title: tip.title,
              description: tip.description,
              onTap: () => controller.onTipPressed(tip),
            );
          },
        );
      },
      onLoading: const Center(child: AppShimmerLoading()),
      onError: (error) => AppEmptyState(
        message: error ?? "Something went wrong!",
        animationPath: AppAnimations.noRecords,
      ),
    );
  }
}
