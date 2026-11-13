import '../../../core/imports/import_manger.dart';

/// One tip, full text. The image (when there is one) keeps a 16:9 box while
/// it loads, so the text does not jump down when it arrives.
class TipDetailsView extends GetView<TipDetailsController> {
  const TipDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TipsModel? tip = controller.tip;

    return Scaffold(
      appBar: CustomAppBar(title: "TipDetailsView_tip_details_title".tr),
      body: tip == null
          ? AppEmptyState(
              icon: Icons.lightbulb_outline_rounded,
              title: "TipDetailsView_empty_state_text".tr,
              actionLabel: "back_label".tr,
              onAction: Get.back,
            )
          : ListView(
              padding: AppSpacing.screenVertical,
              children: <Widget>[
                if (tip.image != null) ...<Widget>[
                  ClipRRect(
                    borderRadius: AppRadius.lgAll,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ColoredBox(
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: Image.network(
                          tip.image!,
                          fit: BoxFit.cover,
                          // Decorative: the text carries the tip.
                          excludeFromSemantics: true,
                          frameBuilder:
                              (_, Widget child, int? frame, bool sync) =>
                                  AnimatedOpacity(
                            opacity: sync || frame != null ? 1 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: child,
                          ),
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.image_not_supported_outlined,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                Semantics(
                  header: true,
                  child: Text(bidiIsolate(tip.title),
                      style: theme.textTheme.headlineSmall),
                ),
                const SizedBox(height: AppSpacing.md),
                SelectableText(
                  bidiIsolate(tip.description.isEmpty
                      ? "no_description".tr
                      : tip.description),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxl),
                const MedicalDisclaimer(compact: true),
              ],
            ),
    );
  }
}
