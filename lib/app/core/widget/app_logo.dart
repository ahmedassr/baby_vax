import 'package:baby_vax/app/core/imports/import_core.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';

import '../../config/themes/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.08),
        ),
        padding: const EdgeInsets.all(18),
        // The real icon in its own colours. This was an ImageIcon pointed at
        // a Lottie JSON file, which cannot decode as an image, so the login
        // screen showed an empty circle.
        child: Image.asset(
          AppImage.appIcon,
          width: 100,
          height: 100,
          semanticLabel: 'Baby Vax',
        ));
  }
}
