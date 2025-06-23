import 'package:baby_vax/app/core/imports/import_manger.dart';

class AppEmptyState extends StatelessWidget {
  final String? animationPath;
  final String? message;
  final double animationHeight;
  final BoxFit fit;
  final Color? background;

  const AppEmptyState(
      {super.key,
      this.animationPath,
      this.message,
      this.background,
      this.animationHeight = 250,
      this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background ?? context.theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (animationPath != null && (animationPath?.isNotEmpty ?? false))
                Center(
                  child: Opacity(
                    opacity: context.isDarkMode ? 0.8 : 1,
                    child: Lottie.asset(
                      animationPath!,
                      height: animationHeight,
                      fit: fit,
                    ),
                  ),
                ),
              AppText(
                text: message ?? "No data found.",
                style: AppTextStyles.titleSmall,
                overflow: TextOverflow.visible,
              )
            ],
          ),
        ),
      ),
    );
  }
}
