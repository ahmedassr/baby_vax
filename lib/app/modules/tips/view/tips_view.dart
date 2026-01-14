import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import '../widget/tip_card.dart';
import '../widget/tips_header.dart';

class TipsView extends GetView<TipsController> {
  const TipsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<TipsController>(() => TipsController());

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: controller.obx(
            (tips) {
          if (tips == null || tips.isEmpty) {
            return const AppEmptyState(
              message: "No tips available yet. Check back later!",
              animationPath: AppAnimations.noRecords,
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.fetchTips(),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: TipsHeader()),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final tip = tips[index];
                        return TipCard(
                          title: tip.title,
                          description: tip.description,
                          icon: Icons.privacy_tip_outlined,
                          onTap: () => controller.onTipPressed(tip),
                        );
                      },
                      childCount: tips.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24), // Bottom spacing
                ),
              ],
            ),
          );
        },
        onLoading: const Center(child: AppShimmerLoading()),
        onError: (error) => AppEmptyState(
          message: error ?? "Something went wrong!",
          animationPath: AppAnimations.noRecords,
        ),
      ),
    );
  }
}
