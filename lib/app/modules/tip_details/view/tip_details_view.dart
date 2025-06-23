import 'package:baby_vax/app/modules/tip_details/controller/tip_details_controller.dart';

import '../../../core/imports/import_manger.dart';
import '../../../core/widget/custom_app_bar.dart';

class TipDetailsView extends GetView<TipDetailsController> {
  const TipDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Tip number 1",
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppConstant.columnPadding,
          child: Column(
            children: [
              KeyValueRichText(label: "Name", value: "tip number 1"),
              20.sbh,
              KeyValueRichText(label: "Description", value: "there is no ..."),

            ],
          ),
        ),
      ),
    );

  }
}
