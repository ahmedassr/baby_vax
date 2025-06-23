import 'package:baby_vax/app/config/constant/app_constant.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/custom_app_bar.dart';

class MedicalDateDetailsView extends GetView {
  const MedicalDateDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Date number 1",
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppConstant.columnPadding,
          child: Column(
            children: [
              KeyValueRichText(label: "Name", value: "date number 1"),
              20.sbh,
              KeyValueRichText(label: "Due Date", value: "21-9-2025"),
              20.sbh,
              KeyValueRichText(label: "State", value: "Coming in / Missed"),
              70.sbh,
              if("21-9-2025" == DateTime.now().toString())
              AppButton(onPressed: (){}, text: "Completed")

            ],
          ),
        ),
      ),
    );
  }
}
