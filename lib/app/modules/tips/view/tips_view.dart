import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';

class TipsView extends GetView<TipsController> {
  const TipsView({super.key});

  @override
  Widget build(BuildContext context) {
    return controller.obx(
      (tips) {
        if (tips != null && tips.isNotEmpty) {
          return RefreshableListBuilder(
            itemCount: tips.length,
            onRefresh: controller.fetchTips,
            itemBuilder: (context, index) {
              return AppDismissibleListItem(
                title: KeyValueRichText(
                  label: tips[index].title,
                  textAlign: TextAlign.start,
                ),
                subTitle: KeyValueRichText(
                    value: tips[index].description, textAlign: TextAlign.start),
                leadingIcon: Icons.privacy_tip_sharp,
                disableDismiss: true,
                hideTrailingIcon: true,
                onTap: () => controller.onTipPressed(tips[index]),
              );
            },
          );
        }
        return const AppEmptyState(
          animationPath: AppAnimations.noRecords,
        );
      },
      onLoading: const AppShimmerLoading(),
      onEmpty: const AppEmptyState(
        animationPath: AppAnimations.noRecords,
      ),
      onError: (error) => AppEmptyState(
        message: error,
        animationPath: AppAnimations.noRecords,
      ),
    );
  }
}
