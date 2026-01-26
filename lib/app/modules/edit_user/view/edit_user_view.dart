import 'package:baby_vax/app/core/imports/import_manger.dart';

class EditUserView extends GetView<EditUserController> {
  const EditUserView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "EditUserView_edit_user_title".tr,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              LabeledTextField(
                  label: "email_label".tr,
                  controller: controller.editUserController["email"] ??
                      TextEditingController()),
              20.sbh,
              LabeledTextField(
                  label: "name_label".tr,
                  controller: controller.editUserController["name"] ??
                      TextEditingController()),
              20.sbh,
              LabeledTextField(
                  label: "weight_label".tr,
                  controller: controller.editUserController["weight"] ??
                      TextEditingController()),
              20.sbh,
              LabeledTextField(
                  label: "height_label".tr,
                  controller: controller.editUserController["height"] ??
                      TextEditingController()),
              20.sbh,
              LabeledTextField(
                  label: "blood_percentage_label".tr,
                  controller:
                      controller.editUserController["bloodPercentage"] ??
                          TextEditingController()),
              20.sbh,
              LabeledTextField(
                  label: "head_size_label".tr,
                  controller: controller.editUserController["headSize"] ??
                      TextEditingController()),
              70.sbh,
              AppButton(
                text: "EditUserView_edit_label".tr,
                onPressed: controller.updateUser,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
