import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/app_logo.dart';

/// "About Baby Vax": the logo, the medical disclaimer, and the way to the
/// open-source licences.
///
/// Flutter's `showAboutDialog` opens the licence page itself, with no way
/// to give it a theme; this dialog opens the same `LicensePage` inside
/// [AppTheme.licenseTheme] (phone review R6).
class AboutBabyVax extends StatelessWidget {
  const AboutBabyVax({super.key});

  static Future<void> show() => Get.dialog<void>(const AboutBabyVax());

  /// Flutter's licence page in the app's theme and font, light or dark.
  static Future<void>? openLicenses() => Get.to<void>(() => Builder(
        builder: (BuildContext context) => Theme(
          data: AppTheme.licenseTheme(Theme.of(context)),
          child: const LicensePage(
            applicationName: 'Baby Vax',
            applicationIcon: Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: AppLogo(size: 48),
            ),
          ),
        ),
      ));

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      key: const Key('about_dialog'),
      title: Row(
        children: <Widget>[
          const AppLogo(size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text('Baby Vax', style: theme.textTheme.titleLarge)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text("MedicalDisclaimer_body".tr),
            const SizedBox(height: AppSpacing.sm),
            Text("MedicalDisclaimer_source".tr,
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('about_licenses'),
          onPressed: () {
            Get.back<void>();
            openLicenses();
          },
          child: Text("Settings_licenses".tr),
        ),
        TextButton(
          key: const Key('about_close'),
          onPressed: () => Get.back<void>(),
          child: Text("close_label".tr),
        ),
      ],
    );
  }
}
