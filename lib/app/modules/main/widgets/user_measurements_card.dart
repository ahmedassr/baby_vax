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
                       const Icon(Icons.monitor_weight, color: AppColors.primary,size: 35,),
                        10.sbh,
                        AppText(
                          text: "Weight\n$weight",
                          style: AppTextStyles.boldLarge,
                        ),
                        30.sbh,
                        const Icon(Icons.bloodtype, color: AppColors.primary,size: 35,),
                        10.sbh,
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
                        const Icon(Icons.height, color: AppColors.primary,size: 35,),
                        10.sbh,
                        AppText(
                            text: "Height\n$height",
                            style: AppTextStyles.boldLarge),
                        30.sbh,
                        const Icon(Icons.account_circle_rounded,
                            color: AppColors.primary,size: 35,),
                        10.sbh,
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
          top: -7,
          right: -5,
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
