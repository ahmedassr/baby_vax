import 'package:baby_vax/app/core/service/vaccine_state_service.dart';
import 'package:baby_vax/app/core/values/languages/app_translations.dart';

import '../../../config/themes/app_status_colors.dart';
import '../../../modules/medical_dates/controller/medical_dates_controller.dart';
import '../../../modules/medical_dates/model/medical_dates_model.dart';
import '../../utils/app_shared_model/user_model.dart';

/// A string in both of the app's languages.
class Bilingual {
  const Bilingual(this.en, this.ar);

  final String en;
  final String ar;
}

/// One row of the card.
class CardRow {
  const CardRow({
    required this.vaccine,
    required this.status,
    required this.displayStatus,
    required this.scheduled,
    this.given,
    this.clinic,
    this.lot,
  });

  final Bilingual vaccine;
  final Bilingual status;
  final DoseDisplayStatus displayStatus;

  /// `dd/MM/yyyy`, Western digits.
  final String scheduled;
  final String? given;
  final String? clinic;
  final String? lot;
}

/// Everything printed on the vaccination card, in both languages, already
/// formatted. Built from the profile and the schedule; no Flutter, no
/// Firebase, so the mapping is unit-tested on its own.
///
/// Dates are `dd/MM/yyyy` with Western digits: a clinic reads that the same
/// way whatever language the card's owner uses, and it matches v1.0's
/// Western-digit fix.
class VaccinationCardData {
  VaccinationCardData._({
    required this.childName,
    required this.birthDate,
    required this.sex,
    required this.rows,
    required this.generatedOn,
    required this.counts,
  });

  /// The card for [user] and [doses] on [now], with text from the app's own
  /// translation tables (both languages, whatever the current one is).
  factory VaccinationCardData.build({
    required UserModel user,
    required Iterable<MedicalDatesModel> doses,
    required DateTime now,
    Map<String, Map<String, String>>? translations,
  }) {
    final Map<String, Map<String, String>> t =
        translations ?? AppTranslations().keys;
    Bilingual tr(String key) =>
        Bilingual(t['en']?[key] ?? key, t['ar']?[key] ?? t['en']?[key] ?? key);

    Bilingual vaccineName(MedicalDatesModel d) {
      final String? code = d.code;
      if (code == null || code.isEmpty) return Bilingual(d.name, d.name);
      final String key = 'Vaccine_${code}_name';
      return Bilingual(
          t['en']?[key] ?? d.name, t['ar']?[key] ?? t['en']?[key] ?? d.name);
    }

    final List<CardRow> rows = <CardRow>[];
    final Map<DoseDisplayStatus, int> counts = <DoseDisplayStatus, int>{};
    for (final MedicalDatesModel d
        in MedicalDatesController.inScheduleOrder(doses)) {
      final DoseDisplayStatus status = VaccineStatePolicy.displayStatus(d, now);
      counts[status] = (counts[status] ?? 0) + 1;
      // A record left on a pending dose by a v1.0 undo is not printed.
      final bool given = status == DoseDisplayStatus.completed;
      final DoseRecord r = given ? d.record : const DoseRecord();
      rows.add(CardRow(
        vaccine: vaccineName(d),
        status: tr(status.translationKey),
        displayStatus: status,
        scheduled: formatDate(d.date),
        given: r.givenDate == null ? null : formatDate(r.givenDate!),
        clinic: r.clinic,
        lot: r.lot,
      ));
    }

    final String birthday = user.birthday ?? '';
    final DateTime? birth =
        birthday.isEmpty ? null : DateTime.tryParse(birthday);
    final String? sexKey = switch (user.sex) {
      'female' => 'sex_female',
      'male' => 'sex_male',
      _ => null,
    };

    return VaccinationCardData._(
      childName: (user.name ?? '').trim(),
      birthDate: birth == null ? null : formatDate(birth),
      sex: sexKey == null ? null : tr(sexKey),
      rows: rows,
      generatedOn: formatDate(now),
      counts: counts,
    );
  }

  final String childName;
  final String? birthDate;
  final Bilingual? sex;
  final List<CardRow> rows;
  final String generatedOn;

  /// How many doses are in each display status.
  final Map<DoseDisplayStatus, int> counts;

  /// `dd/MM/yyyy`, Western digits, in every language. Built by hand so it
  /// needs no locale data.
  static String formatDate(DateTime d) =>
      '${_two(d.day)}/${_two(d.month)}/${d.year.toString().padLeft(4, '0')}';

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// A file name with no spaces or characters a share target might reject.
  String get fileName {
    final String slug = childName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty
        ? 'baby-vax-vaccination-card.pdf'
        : 'baby-vax-vaccination-card-$slug.pdf';
  }
}
