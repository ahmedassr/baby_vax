import 'package:baby_vax/app/core/imports/import_manger.dart';

class MedicalDateStatusBadge extends StatelessWidget {
  final MedicalDateStateEnum state;

  const MedicalDateStatusBadge({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bg;
    Color fg;

    switch (state) {
      case MedicalDateStateEnum.completed:
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green.shade700;
        break;
      case MedicalDateStateEnum.skipped:
        bg = theme.colorScheme.error.withValues(alpha: 0.12);
        fg = theme.colorScheme.error;
        break;
      case MedicalDateStateEnum.pending:
        bg = AppColors.primary.withValues(alpha: 0.1);
        fg = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AppText(
        text: state.label,
        style: AppTextStyles.captionMedium.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}



