import '../../../core/imports/import_manger.dart';
import '../widget/detail_card.dart';

class TipDetailsView extends GetView<TipDetailsController> {
  const TipDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Tip Details",
        fontSize: 16,
        background: colorScheme.background,
        foreground: colorScheme.onBackground,
      ),
      body: controller.tip == null
          ? const AppEmptyState(
              message: "Tip details are not available.",
              animationPath: AppAnimations.noRecords,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailCard(
                    title: controller.tip!.title,
                    description: controller.tip!.description,
                    image: controller.tip!.image,
                  )
                ],
              ),
            ),
    );
  }
}
