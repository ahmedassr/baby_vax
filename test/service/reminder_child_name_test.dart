import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/values/languages/app_translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => Get.addTranslations(AppTranslations().keys));
  tearDown(Get.reset);

  test('uses the name from the Firestore user doc', () {
    Get.locale = const Locale('en');
    expect(reminderChildName('Lina'), 'Lina');
    expect(reminderChildName('  Lina  '), 'Lina');
    expect(reminderChildName('ليلى'), 'ليلى');
  });

  test('falls back to a localized "Your baby" when the name is missing', () {
    Get.locale = const Locale('en');
    expect(reminderChildName(null), 'Your baby');
    expect(reminderChildName('   '), 'Your baby');
    Get.locale = const Locale('ar');
    expect(reminderChildName(''), 'طفلك');
  });
}
