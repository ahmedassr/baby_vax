import 'package:baby_vax/app/core/imports/import_manger.dart';

class EditUserView extends GetView<EditUserController> {
  const EditUserView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Edit User",
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              LabeledTextField(
                  label: "Email",
                  controller: controller.editUserController["email"] ??
                      TextEditingController()),
              20.sbh,
              LabeledTextField(
                  label: "Name",
                  controller: controller.editUserController["name"] ??
                      TextEditingController()),
              20.sbh,
              LabeledTextField(
                  label: "Weight",
                  controller: controller.editUserController["weight"] ??
                      TextEditingController()),
              20.sbh,
              LabeledTextField(
                  label: "Height",
                  controller: controller.editUserController["height"] ??
                      TextEditingController()),
              20.sbh,
              LabeledTextField(
                  label: "Blood Percentage:",
                  controller: controller.editUserController["bloodPercentage"] ??
                      TextEditingController()),
              20.sbh,
              LabeledTextField(
                  label: "Head Size",
                  controller: controller.editUserController["headSize"] ??
                      TextEditingController()),
              70.sbh,
              AppButton(
                text: "Edit",
                onPressed: controller.updateUser,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
