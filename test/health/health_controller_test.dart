import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';
import 'package:baby_vax/app/modules/health/controller/health_controller.dart';
import 'package:baby_vax/app/modules/health/model/health_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

/// A health log held in memory, in place of Firestore.
class FakeHealthStore {
  FakeHealthStore([List<HealthEntry>? entries])
      : entries = List<HealthEntry>.of(entries ?? <HealthEntry>[]);

  final List<HealthEntry> entries;
  int next = 0;
  bool offline = false;

  HealthController controller({
    UserModel? user,
    List<MedicalDatesModel>? doses,
    DateTime? now,
  }) =>
      HealthController(
        load: (_) async => List<HealthEntry>.of(entries),
        save: (_, e) async {
          final String id = e.id ?? 'n${next++}';
          entries.removeWhere((x) => x.id == id);
          entries.add(e.copyWith(id: id));
          return (id, offline ? WriteOutcome.pendingSync : WriteOutcome.synced);
        },
        delete: (_, id) async => entries.removeWhere((x) => x.id == id),
        user: () => user ?? sampleUser(),
        doses: () => doses ?? sampleSchedule(),
        clock: () => now ?? fixedNow,
      );
}

void main() {
  setUp(() => SessionManager.authUid = () => 'alice');
  tearDown(() {
    SessionManager.authUid = () => null;
    Get.reset();
  });

  HealthEntry temp(DateTime at, double c,
          [TemperatureMethod m = TemperatureMethod.armpit]) =>
      HealthEntry(
          kind: HealthEntryKind.temperature, at: at, tempC: c, method: m);

  test('loads newest first; saves and deletes', () async {
    final FakeHealthStore store = FakeHealthStore(<HealthEntry>[
      temp(DateTime(2027, 3, 9, 8), 37.0).copyWith(id: 'a'),
      temp(DateTime(2027, 3, 10, 8), 38.1).copyWith(id: 'b'),
    ]);
    final HealthController c = store.controller();
    await c.fetch();
    expect(c.items.map((e) => e.id), <String>['b', 'a']);
    expect(await c.saveEntry(temp(DateTime(2027, 3, 10, 11), 37.9)), isTrue);
    expect(c.items.first.id, 'n0');
    await c.deleteEntry(c.items.last);
    expect(c.items.map((e) => e.id), <String>['n0', 'b']);
  });

  test('an incomplete entry is never written', () async {
    final FakeHealthStore store = FakeHealthStore();
    final HealthController c = store.controller();
    expect(
        await c.saveEntry(
            HealthEntry(kind: HealthEntryKind.symptoms, at: fixedNow)),
        isFalse);
    expect(store.entries, isEmpty);
  });

  test('offline: kept, and flagged as waiting to sync', () async {
    final FakeHealthStore store = FakeHealthStore()..offline = true;
    final HealthController c = store.controller();
    await c.saveEntry(temp(fixedNow, 37.2));
    expect(c.savedOffline.value, isTrue);
    expect(c.items, hasLength(1));
  });

  test('WHO message is judged at the age when it was logged', () {
    // Born 15 Jan 2027: a young infant until 15 Mar 2027.
    final HealthController c = FakeHealthStore().controller();
    expect(c.careLevelOf(temp(DateTime(2027, 3, 10), 37.6)), CareLevel.urgent);
    expect(c.careLevelOf(temp(DateTime(2027, 4, 10), 37.6)),
        CareLevel.seeHealthWorker);
    expect(
        c.careLevelOf(temp(DateTime(2027, 3, 10), 39, TemperatureMethod.other)),
        CareLevel.none);
  });

  test('chart window, latest temperature, last medicine, by day', () async {
    final FakeHealthStore store = FakeHealthStore(<HealthEntry>[
      temp(fixedNow.subtract(const Duration(hours: 80)), 37.0)
          .copyWith(id: 'old'),
      temp(fixedNow.subtract(const Duration(hours: 5)), 38.0)
          .copyWith(id: 't1'),
      temp(fixedNow.subtract(const Duration(hours: 1)), 37.6)
          .copyWith(id: 't2'),
      HealthEntry(
              id: 'm',
              kind: HealthEntryKind.medicine,
              at: fixedNow.subtract(const Duration(hours: 3)),
              medicine: 'Paracetamol')
          .copyWith(),
    ]);
    final HealthController c = store.controller();
    await c.fetch();
    expect(c.recentTemperatures.map((e) => e.id), <String>['t1', 't2']);
    expect(c.latestTemperature!.id, 't2');
    expect(c.lastMedicine!.id, 'm');
    expect(c.byDay.first.$1, DateTime(2027, 3, 10));
  });

  group('after vaccination', () {
    List<MedicalDatesModel> givenOn(DateTime day) {
      final List<MedicalDatesModel> s = sampleSchedule();
      s[1] =
          s[1].copyWith(state: 'Completed', record: DoseRecord(givenDate: day));
      return s;
    }

    test('the dose given in the last three days, with the day count', () {
      final HealthController c = FakeHealthStore()
          .controller(doses: givenOn(DateTime(2027, 3, 9, 10)));
      expect(c.recentDose?.code, sampleSchedule()[1].code);
      expect(c.dayAfter(c.recentDose!), 2);
    });

    test('gone after three days', () {
      final HealthController c =
          FakeHealthStore().controller(doses: givenOn(DateTime(2027, 3, 7)));
      expect(c.recentDose, isNull);
    });

    test('nothing given recently, nothing shown', () {
      expect(FakeHealthStore().controller().recentDose, isNull);
    });
  });

  test('logout forgets the log', () async {
    final HealthController c =
        FakeHealthStore(<HealthEntry>[temp(fixedNow, 37).copyWith(id: 'a')])
            .controller();
    await c.fetch();
    c.clearSession();
    expect(c.items, isEmpty);
  });
}
