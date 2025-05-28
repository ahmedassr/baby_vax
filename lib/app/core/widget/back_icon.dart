import 'package:baby_vax/app/core/imports/import_library.dart';

class BackIcon extends StatelessWidget {
  final Function()? onTap;

  const BackIcon({
    super.key,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          Get.back();
        }
      },
      child: CircleAvatar(
        radius: 20.r,
        backgroundColor: Colors.grey.shade200,
        child: Icon(
          Icons.arrow_back_outlined,
          color: Colors.grey.shade900,
          size: 20.w,
        ),
      ),
    );
  }
}
