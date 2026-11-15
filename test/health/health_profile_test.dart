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
      expect(find.byType(ChoiceChip),
          findsNWidgets(9 + EmergencyContact.relations.length));
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

  group('EmergencyContact', () {
    test('normalizePhone keeps digits and a leading +', () {
      expect(EmergencyContact.normalizePhone('0599 123-456'), '0599123456');
      expect(EmergencyContact.normalizePhone('+970 (599) 123.456'),
          '+970599123456');
      expect(EmergencyContact.normalizePhone('٠٥٩٩١٢٣٤٥٦'), '0599123456');
      expect(EmergencyContact.normalizePhone('۰۵۹۹۱۲۳۴۵۶'), '0599123456');
      expect(EmergencyContact.normalizePhone('‎0599123456‎'), '0599123456');
      expect(EmergencyContact.normalizePhone('12345'), isNull,
          reason: 'too short');
      expect(EmergencyContact.normalizePhone('1' * 16), isNull,
          reason: 'too long');
      expect(EmergencyContact.normalizePhone('0599+123456'), isNull);
      expect(EmergencyContact.normalizePhone('Mum 0599123456'), isNull);
      expect(EmergencyContact.normalizePhone(''), isNull);
    });

    test('reads only a valid map, and writes what the rules accept', () {
      expect(EmergencyContact.fromJson('Mum 0599 000 000'), isNull);
      expect(
          EmergencyContact.fromJson(<String, dynamic>{'name': 'Mum'}), isNull);
      expect(
          EmergencyContact.fromJson(
              <String, dynamic>{'name': ' ', 'phone': '0599000000'}),
          isNull);
      final EmergencyContact? c = EmergencyContact.fromJson(<String, dynamic>{
        'name': ' Sara ',
        'phone': '0599000000',
        'relation': 'aunt',
      });
      expect(c, const EmergencyContact(name: 'Sara', phone: '0599000000'),
          reason: 'an unknown relation is dropped');
      expect(
          const EmergencyContact(
                  name: 'Sara', phone: '+970599000000', relation: 'mother')
              .toMap(),
          <String, Object>{
            'name': 'Sara',
            'phone': '+970599000000',
            'relation': 'mother'
          });
      final UserModel u = UserModel.fromJson(<String, dynamic>{
        'uid': 'u',
        'email': 'p@example.com',
        'emergencyContact': <String, dynamic>{
          'name': 'Omar',
          'phone': '0599000000',
          'relation': 'father'
        },
      });
      expect(u.emergencyContact!.relation, 'father');
      expect(u.hasHealthProfile, isTrue);
      expect(u.toMap()['emergencyContact'], <String, Object>{
        'name': 'Omar',
        'phone': '0599000000',
        'relation': 'father'
      });
    });

    test('contactFrom: both blank clears, one blank or a bad number explains',
        () {
      expect(HealthProfileSheet.contactFrom(' ', '', 'mother').contact, isNull);
      expect(HealthProfileSheet.contactFrom('', '', null).nameError, isNull);
      final r1 = HealthProfileSheet.contactFrom('Sara', '', null);
      expect(r1.phoneError, "Health_contact_phone_needed".tr);
      expect(r1.nameError, isNull);
      final r2 = HealthProfileSheet.contactFrom('', '0599000000', null);
      expect(r2.nameError, "Health_contact_name_needed".tr);
      final r3 = HealthProfileSheet.contactFrom('Sara', '05-99', null);
      expect(r3.phoneError, "Health_contact_phone_invalid".tr);
      final r4 =
          HealthProfileSheet.contactFrom(' Sara ', '0599 000 000', 'mother');
      expect(
          r4.contact,
          const EmergencyContact(
              name: 'Sara', phone: '0599000000', relation: 'mother'));
    });
  });

  for (final Variant v in <Variant>[
    const Variant('en', Brightness.light, 1.0),
    const Variant('ar', Brightness.dark, 1.3),
  ]) {
    testWidgets('emergency contact: name, relation, phone ($v)',
        (tester) async {
      final out = await open(tester, sampleUser(), variant: v);
      Future<void> tapKey(String k) async {
        await tester.ensureVisible(find.byKey(Key(k)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key(k)));
        await tester.pumpAndSettle();
      }

      // A name with no number is not saved; the field says why.
      await tester.enterText(field('health_contact_name'), 'Sara');
      await tester.pumpAndSettle();
      await tapKey('health_profile_save');
      expect(out, isEmpty, reason: 'the sheet stays open');
      expect(find.text("Health_contact_phone_needed".tr), findsOneWidget);
      expectNoOverflow(tester);

      // A number that is not one.
      await tester.enterText(field('health_contact_phone'), '12');
      await tester.pumpAndSettle();
      expect(find.text("Health_contact_phone_needed".tr), findsNothing,
          reason: 'typing clears the message');
      await tapKey('health_profile_save');
      expect(find.text("Health_contact_phone_invalid".tr), findsOneWidget);

      // Arabic-Indic digits and spaces are fine.
      await tester.enterText(field('health_contact_phone'), '٠٥٩٩ ١٢٣ ٤٥٦');
      await tester.pumpAndSettle();
      await tapKey('health_relation_grandparent');
      await tapKey('health_profile_save');
      expect(
          out.single!.emergencyContact,
          const EmergencyContact(
              name: 'Sara', phone: '0599123456', relation: 'grandparent'));
    });
  }

  testWidgets('the phone field reads left to right in Arabic', (tester) async {
    await open(tester, sampleUser(),
        variant: const Variant('ar', Brightness.light, 1.0));
    final TextField f = tester.widget<TextField>(field('health_contact_phone'));
    expect(f.textDirection, TextDirection.ltr);
    expect(f.keyboardType, TextInputType.phone);
  });

  testWidgets('tapping the chosen relation again clears it', (tester) async {
    final out = await open(
        tester,
        sampleUser().withHealth(
            allergies: null,
            conditions: null,
            bloodType: null,
            emergencyContact: const EmergencyContact(
                name: 'Omar', phone: '0599000000', relation: 'father')));
    await tester.ensureVisible(find.byKey(const Key('health_relation_father')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health_relation_father')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('health_profile_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health_profile_save')));
    await tester.pumpAndSettle();
    expect(out.single!.emergencyContact,
        const EmergencyContact(name: 'Omar', phone: '0599000000'));
  });

  testWidgets('clearing name and number removes the contact', (tester) async {
    final out = await open(
        tester,
        sampleUser().withHealth(
            allergies: 'Eggs',
            conditions: null,
            bloodType: null,
            emergencyContact: const EmergencyContact(
                name: 'Omar', phone: '0599000000', relation: 'father')));
    await tester.enterText(field('health_contact_name'), '');
    await tester.enterText(field('health_contact_phone'), '');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('health_profile_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health_profile_save')));
    await tester.pumpAndSettle();
    expect(out.single!.emergencyContact, isNull);
    expect(out.single!.allergies, 'Eggs');
  });

  test('saving writes the contact as a map', () async {
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
    await c.saveProfile(sampleUser().withHealth(
        allergies: null,
        conditions: null,
        bloodType: null,
        emergencyContact: const EmergencyContact(
            name: 'Sara', phone: '+970599000000', relation: 'mother')));
    expect(writes.single['emergencyContact'], <String, Object>{
      'name': 'Sara',
      'phone': '+970599000000',
      'relation': 'mother'
    });
  });
}
