import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/custom_app_bar.dart';
import 'package:baby_vax/app/modules/medical_date_details/controller/medical_date_details_controller.dart';
import 'package:intl/intl.dart';

class MedicalDateDetailsView extends GetView<MedicalDateDetailsController> {
  const MedicalDateDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat("dd-M-yyyy").format(DateTime.now());
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.medicalDate?.name ?? "",
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppConstant.columnPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.sbh,
              KeyValueRichText(
                  label: "Name", value: controller.medicalDate?.name ?? ""),
              20.sbh,
              KeyValueRichText(
                  label: "Due Date",
                  value: controller.medicalDate?.date ?? "00-00-0000"),
              20.sbh,
              KeyValueRichText(
                  label: "State", value:  ""),
              70.sbh,
              if ("01-7-2025" == today)
                Center(child: AppButton(onPressed: () {}, text: "Completed"))
            ],
          ),
        ),
      ),
    );
  }
}
