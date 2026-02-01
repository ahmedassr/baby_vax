import 'package:baby_vax/app/core/imports/import_library.dart';

import '../../config/constant/app_colors.dart';

class AppLogo extends StatelessWidget{
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.08),
        ),
        padding: const EdgeInsets.all(18),
        child: const ImageIcon(
          AssetImage("assets/appIcon.png"),
          size: 100,
          color: AppColors.primary,
        )
    );
  }

}