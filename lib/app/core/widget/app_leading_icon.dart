import 'package:baby_vax/app/core/imports/import_library.dart';

import '../../config/constant/app_colors.dart';

class AppLeadingIcon extends StatelessWidget {
  final IconData icon;

  const AppLeadingIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: AppColors.primary,
        size: 26,
      ),
    );
  }
}
