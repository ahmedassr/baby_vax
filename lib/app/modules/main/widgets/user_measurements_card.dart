import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'measurement_card.dart';

class UserMeasurementCard extends StatelessWidget {
  final String bloodPercentage;
  final String weight;
  final String headSize;
  final String height;

  const UserMeasurementCard({
    super.key,
    required this.weight,
    required this.height,
    required this.bloodPercentage,
    required this.headSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              12.sbw,
              AppText(
                text: "Baby Measurements",
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          24.sbh,
          // Grid Layout
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              MeasurementCard(
                icon: Icons.monitor_weight_outlined,
                title: "Weight",
                value: weight,
                onTap: () {
                  // Handle tap if needed
                },
              ),
              MeasurementCard(
                icon: Icons.height_outlined,
                title: "Height",
                value: height,
                onTap: () {
                  // Handle tap if needed
                },
              ),
              MeasurementCard(
                icon: Icons.bloodtype_outlined,
                title: "Blood Percentage",
                value: bloodPercentage,
                onTap: () {
                  // Handle tap if needed
                },
              ),
              MeasurementCard(
                icon: Icons.account_circle_outlined,
                title: "Head Size",
                value: headSize,
                onTap: () {
                  // Handle tap if needed
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
