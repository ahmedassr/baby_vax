import 'package:baby_vax/app/core/imports/import_manger.dart';

class MedicalDateActions extends StatelessWidget {
  final bool isCompleted;
  final bool isActive;
  final VoidCallback? onMarkCompleted;

  const MedicalDateActions({
    super.key,
    required this.isCompleted,
    required this.isActive,
    this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            text: "Done",
            onPressed: () => Get.back(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          onPressed: isActive ? onMarkCompleted : null,
          text: MedicalDateStateEnum.completed.label,
        ),
      ],
    );
  }
}



