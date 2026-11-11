import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';
import 'package:get/get.dart';

/// What to show for a dose, in the current language.
///
/// Generated doses carry a stable `code`, and their name and description
/// come from the translation files under `Vaccine_<code>_name` and
/// `Vaccine_<code>_description`. The stored `name`/`description` are only a
/// fallback (an unknown code from a newer app version, say).
///
/// Custom dates the user adds have no code and always show the user's own
/// text, untranslated.
extension MedicalDateDisplay on MedicalDatesModel {
  String get displayName => _byCode('name') ?? name;

  String get displayDescription => _byCode('description') ?? description;

  String? _byCode(String field) {
    final String? c = code;
    if (c == null || c.isEmpty) return null;
    final String key = 'Vaccine_${c}_$field';
    final String translated = key.tr;
    return translated == key ? null : translated;
  }
}
