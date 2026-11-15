import 'package:baby_vax/app/core/imports/import_core.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';

/// The Baby Vax mark, read by TalkBack as the app name.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88});

  /// Height of the mark. Its width follows the artwork's 5:6 aspect.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppImage.appLogo,
      height: size,
      width: size * 5 / 6,
      fit: BoxFit.contain,
      semanticLabel: 'Baby Vax',
    );
  }
}
