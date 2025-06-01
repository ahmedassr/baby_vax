import 'package:baby_vax/app/core/imports/import_manger.dart';

class AlertWidget extends StatelessWidget {
  final AlertModel alert;

  const AlertWidget({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Get.theme;
    return Center(
        child: AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: _buildTitle(theme),
      content: _buildContent(theme),
      actions: _buildActionButton(theme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ));
  }

  Widget? _buildTitle(ThemeData theme) {
    if (alert.title == null || (alert.title?.isEmpty ?? true)) return null;
    return AppText(
      text: alert.title ?? "",
      style: AppTextStyles.bodyMedium.copyWith(
          color: (Get.context?.isDarkMode ?? false)
              ? AppColors.backgroundLight
              : AppColors.backgroundDark),
      textAlign: TextAlign.center,
    );
  }

  Widget? _buildContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (alert.imagePath != null) ...[
          Image.asset(alert.imagePath ?? ""),
          16.sbh
        ],
        AppText(
          text: alert.message ?? "",
          style: AppTextStyles.bodyLarge.copyWith(
            color: theme.textTheme.bodyLarge?.color,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }

  List<Widget> _buildActionButton(ThemeData theme) {
    return [
      AppButton(
        text: alert.yesButtonText ?? 'OK',
        onPressed: () {
          Get.back();
          alert.yesAction?.call();
        },
      ),
      if (alert.additionalAction != null) ...[
        16.sbh,
        AppButton(
          text: alert.additionalButtonText ?? 'Cancel',
          onPressed: () {
            Get.back();
            alert.additionalAction?.call();
          },
        ),
      ],
      if (alert.noAction != null) ...[
        16.sbh,
        AppButton(
          text: alert.noButtonText ?? 'Cancel',
          onPressed: () {
            Get.back();
            alert.noAction?.call();
          },
        ),
      ],
    ];
  }
}
