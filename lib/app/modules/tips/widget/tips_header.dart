import 'package:baby_vax/app/core/imports/import_manger.dart';

class TipsHeader extends StatelessWidget {
  const TipsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: "TipsHeader_tips_title".tr,
            style: AppTextStyles.headLineSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          8.sbh,
          AppText(
            text: "TipsHeader_tips_hint".tr,
            maxLines: 3,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha:0.7),
            ),
          ),
          16.sbh,
        ],
      ),
    );
  }
}
