import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/health/controller/health_controller.dart';
import 'package:baby_vax/app/modules/health/widgets/health_profile_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

Finder field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  setUp(() => SessionManager.authUid = () => 'alice');
  tearDown(() {
    SessionManager.authUid = () => null;
    Get.reset();
  });

  Future<List<UserModel?>> open(WidgetTester tester, UserModel user,
      {Variant variant = const Variant('en', Brightness.light, 1.0)}) async {
    final List<UserModel?> out = <UserModel?>[];
    await pumpApp(
      tester,
      Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async => out.add(await HealthProfileSheet.show(user)),
            child: const Text('open'),
          ),
        ),
      ),
      variant: variant,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return out;
  }

  for (final Variant v in mainVariants) {
    testWidgets('health profile sheet fits ($v)', (tester) async {
      await open(tester, sampleUser(), variant: v);
      expect(find.text("Health_profile_title".tr), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(9));
      expectNoOverflow(tester);
      await tester.ensureVisible(find.byKey(const Key('health_profile_save')));
      await tester.pumpAndSettle();
      expectNoOverflow(tester);
    });
  }

  testWidgets('fills, picks a blood type, clears a field', (tester) async {
    final out = await open(
        tester,
        sampleUser().withHealth(
            allergies: null,
            conditions: 'Asthma',
            bloodType: null,
            emergencyContact: null));
    await tester.enterText(field('health_allergies'), 'Penicillin');
    await tester.enterText(field('health_conditions'), '');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('health_blood_O+')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health_blood_O+')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('health_profile_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health_profile_save')));
    await tester.pumpAndSettle();
    final UserModel u = out.single!;
    expect(u.allergies, 'Penicillin');
    expect(u.conditions, isNull);
    expect(u.bloodType, 'O+');
    expect(u.name, 'Lina', reason: 'the rest of the profile is kept');
  });

  test('saving removes blank fields and updates the profile at once', () async {
    final List<Map<String, dynamic>> writes = <Map<String, dynamic>>[];
    final HealthController c = HealthController(
      load: (_) async => const [],
      save: (_, e) async => ('x', WriteOutcome.synced),
      delete: (_, __) async {},
      updateProfile: (_, f) async => writes.add(f),
      user: () => sampleUser(),
      doses: () => const <MedicalDatesModel>[],
      clock: () => fixedNow,
    );
    final UserModel updated = sampleUser().withHealth(
        allergies: 'Penicillin',
        conditions: '  ',
        bloodType: 'B-',
        emergencyContact: null);
    expect(await c.saveProfile(updated), isTrue);
    expect(writes.single['allergies'], 'Penicillin');
    expect(writes.single['bloodType'], 'B-');
    expect(writes.single['conditions'], isA<FieldValue>());
    expect(writes.single['emergencyContact'], isA<FieldValue>());
    expect(writes.single.keys,
        unorderedEquals(<String>[...UserModel.healthFields]));
    expect(c.profile!.allergies, 'Penicillin');
  });
}
