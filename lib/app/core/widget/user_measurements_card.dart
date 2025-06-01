import 'package:baby_vax/app/core/imports/import_manger.dart';

class UserMeasurementCard extends StatelessWidget {
  final String bloodPercentage;
  final String weight;
  final String headSize;
  final String height;

  const UserMeasurementCard(
      {super.key,
      required this.weight,
      required this.height,
      required this.bloodPercentage,
      required this.headSize});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
            child: Column(
              children: [
                AppText(
                  text: "Baby Measurements",
                  style: AppTextStyles.headLineMedium
                      .copyWith(fontSize: 22, color: AppColors.primary),
                ),
                30.sbh,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: "Weight\n$weight",
                          style: AppTextStyles.boldLarge,
                        ),
                        30.sbh,
                        AppText(
                            text: "Blood Percentage\n$bloodPercentage",
                            maxLines: 2,
                            style: AppTextStyles.boldLarge),
                      ],
                    ),
                    40.sbw,
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                            text: "Height\n$height",
                            style: AppTextStyles.boldLarge),
                        30.sbh,
                        AppText(
                            text: "Head Size\n$headSize",
                            style: AppTextStyles.boldLarge),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -20,
          right: -15,
          child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.edit,
                size: 40,
                color: AppColors.primary,
              )),
        ),
      ],
    );
  }
}
