import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/values/languages/ar.dart';
import 'package:baby_vax/app/core/values/languages/en.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {"en": en, "ar": ar};
}
