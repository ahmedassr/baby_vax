import '../../../core/imports/import_manger.dart';

class TipDetailsView extends GetView<TipDetailsController> {
  const TipDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.tip?.title ?? "",
        fontSize: 12,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppConstant.columnPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.sbh,
              KeyValueRichText(
                label: controller.tip?.title ?? "",
                textAlign: TextAlign.right,
              ),
              20.sbh,
              if (controller.tip?.image?.isNotEmpty ?? false)
                Image.network(
                  controller.tip?.image ?? "",
                  loadingBuilder: (context, image, loadingProgress) {
                    if (loadingProgress == null) {
                      return image;
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 150,
                    decoration:  const BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius:  BorderRadius.all(Radius.circular(8))
                    ),
                    child: const Icon(Icons.broken_image,
                        size: 120, color: Colors.white),
                  ),
                ),
              20.sbh,
              AppText(
                text: controller.tip?.description ?? "",
                style: AppTextStyles.captionLarge
                    .copyWith(fontSize: 15, wordSpacing: 4),
                textAlign: TextAlign.right,
                maxLines: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
