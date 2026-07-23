import 'package:baby_vax/app/config/themes/app_colors.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmerLoading extends StatelessWidget {
  final bool isGridView;
  final bool isListView;
  final int itemCount;
  final double height;
  final double? width;
  final int gridCrossAxisCount;

  const AppShimmerLoading(
      {super.key,
      this.isGridView = false,
      this.isListView = true,
      this.itemCount = 5,
      this.width,
      this.height = 150,
      this.gridCrossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    final baseColor =
        context.isDarkMode ? AppColors.greyDark : AppColors.greyLight;
    final highLightColor =
        context.isDarkMode ? AppColors.greyMedium : AppColors.white;
    if (isGridView) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => shimmerItem(baseColor, highLightColor),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCrossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
        ),
      );
    }

    if (isListView) {
      return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: itemCount,
          itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: shimmerItem(baseColor, highLightColor),
              ));
    } else {
      return Column(
          children: List.generate(
              itemCount,
              (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: shimmerItem(baseColor, highLightColor),
                  )));
    }
  }

  Widget shimmerItem(Color baseColor, Color highLightColor) {
    return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highLightColor,
        child: Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(15),
            border:
                Border.all(color: baseColor.withValues(alpha: 0.5), width: 0.5),
          ),
        ));
  }
}
