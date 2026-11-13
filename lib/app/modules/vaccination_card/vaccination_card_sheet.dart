import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/vaccination_card/vaccination_card_service.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';

/// "Vaccination card": explains what the PDF is, then Share or Print.
///
/// Reads the profile and schedule the home screen already loaded, so it
/// works offline.
class VaccinationCardSheet extends StatefulWidget {
  const VaccinationCardSheet({super.key, this.service});

  /// Injectable for tests.
  final VaccinationCardService? service;

  /// Opens the sheet.
  static Future<void> show({VaccinationCardService? service}) =>
      Get.bottomSheet<void>(VaccinationCardSheet(service: service),
          isScrollControlled: true);

  @override
  State<VaccinationCardSheet> createState() => _VaccinationCardSheetState();
}

class _VaccinationCardSheetState extends State<VaccinationCardSheet> {
  late final VaccinationCardService _service =
      widget.service ?? VaccinationCardService();
  bool _busy = false;
  String? _error;

  Future<void> _run(
      Future<void> Function(UserModel, List<MedicalDatesModel>) action) async {
    final HomeController home = Get.find<HomeController>();
    final UserModel? user = home.userDetails.value;
    if (user == null) {
      setState(() => _error = "Card_failed".tr);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(user, home.doses.toList());
    } catch (e, s) {
      logger.w('Vaccination card failed', error: e, stackTrace: s);
      if (mounted) setState(() => _error = "Card_failed".tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: AppSpacing.sheet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const AppIconBadge(icon: Icons.picture_as_pdf_rounded, size: 48),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child:
                      Text("Card_export".tr, style: theme.textTheme.titleLarge),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text("Card_export_hint".tr, style: theme.textTheme.bodyMedium),
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            AppBanner(
                key: const Key('card_error'),
                tone: AppBannerTone.error,
                message: _error!),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            key: const Key('card_share'),
            text: "Card_share".tr,
            icon: Icons.share_rounded,
            loading: _busy,
            onPressed: () => _run(_service.share),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const Key('card_print'),
            text: "Card_print".tr,
            icon: Icons.print_rounded,
            variant: AppButtonVariant.outline,
            onPressed: _busy ? null : () => _run(_service.print),
          ),
          const SizedBox(height: AppSpacing.lg),
          const MedicalDisclaimer(compact: true),
        ],
      ),
    );
  }
}
