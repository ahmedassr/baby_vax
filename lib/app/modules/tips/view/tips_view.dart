import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';


class TipsView extends GetView<TipsController> {
  const TipsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<TipsController>(() => TipsController());
    return controller.obx(
      (tips) {
        if (tips != null && tips.isNotEmpty) {
          return RefreshableListBuilder(
              itemBuilder: (context, index) {
                return AppDismissibleListItem(
                  title: KeyValueRichText(
                      label: "Name:", value: tips[index].title),
                  subTitle: KeyValueRichText(
                      label: "Description:", value: tips[index].description),
                  leadingIcon: Icons.privacy_tip_sharp,
                  disableDismiss: true,
                  hideTrailingIcon: true,
                  onTap: () {},
                );
              },
              itemCount: tips.length);
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
