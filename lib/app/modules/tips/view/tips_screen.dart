import 'package:baby_vax/app/core/imports/import_manger.dart';

import 'tips_view.dart';

/// The tips list as its own screen, opened from Home's "See all tips"
/// (Tips is no longer a tab).
class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "MainMenuController_tips_title".tr),
      body: const TipsView(),
    );
  }
}
