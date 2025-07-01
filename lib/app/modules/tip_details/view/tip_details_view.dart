import 'package:baby_vax/app/modules/tip_details/controller/tip_details_controller.dart';

import '../../../core/imports/import_manger.dart';
import '../../../core/widget/custom_app_bar.dart';

class TipDetailsView extends GetView<TipDetailsController> {
  const TipDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.tip?.title ?? "",
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppConstant.columnPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.sbh,
              KeyValueRichText(
                  label: "Name", value: controller.tip?.title ?? ""),
              20.sbh,
              KeyValueRichText(
                  label: "Description",
                  value: controller.tip?.description ?? ""),
            ],
          ),
        ),
      ),
    );
  }
}
