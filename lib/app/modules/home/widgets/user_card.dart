import 'package:baby_vax/app/core/imports/import_manger.dart';

class UserCard extends StatelessWidget {
  final IconData? icon;
  final String name;
  final String email;

  const UserCard(
      {super.key, required this.name, required this.email, this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: context.isDarkMode
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              radius: 40,
              child: Icon(
                icon ?? Icons.person,
                color: AppColors.primary,
                size: 50,
              ),
            ),
            5.sbw,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: name,
                  style: AppTextStyles.headLineSmall.copyWith(fontSize: 19),
                ),
                5.sbh,
                AppText(
                  text: email,
                  style: AppTextStyles.bodyMedium,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
