import '../../../core/imports/import_manger.dart';

class TipDetailsView extends GetView<TipDetailsController> {
  const TipDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "TipDetailsView_tip_details_title".tr,
        fontSize: 18,
      ),
      body: controller.tip == null
          ? AppEmptyState(
              title: "TipDetailsView_empty_state_text".tr,
              animationPath: AppAnimations.noRecords,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        width: 1.4,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (controller.tip!.image?.isNotEmpty ?? false)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              controller.tip!.image!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 170,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, _, __) => SizedBox(
                                height: 80,
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported_rounded,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2),
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (controller.tip!.image?.isNotEmpty ?? false)
                          const SizedBox(height: 22),
                        Text(
                          controller.tip!.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          controller.tip!.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 1.6,
                            letterSpacing: 0.07,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
    );
  }
}
