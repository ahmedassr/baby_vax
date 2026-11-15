// The Health log's "get help" messages follow WHO IMCI (2014) exactly;
// these tests pin each figure and list to the booklet.

import 'package:baby_vax/app/core/service/health/health_guidance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fever (IMCI p.4: 37.5 °C armpit; rectal about 0.5 °C higher)', () {
    test('armpit', () {
      expect(HealthGuidance.isFever(37.4, TemperatureMethod.armpit), isFalse);
      expect(HealthGuidance.isFever(37.5, TemperatureMethod.armpit), isTrue);
    });
    test('rectal', () {
      expect(HealthGuidance.isFever(37.9, TemperatureMethod.rectal), isFalse);
      expect(HealthGuidance.isFever(38.0, TemperatureMethod.rectal), isTrue);
    });
    test('no WHO figure for other methods, so no judgement', () {
      expect(HealthGuidance.isFever(39.0, TemperatureMethod.other), isNull);
      expect(
          HealthGuidance.forTemperature(39.0, TemperatureMethod.other,
              youngInfant: true),
          CareLevel.none);
    });
  });

  group('young infant (up to 2 months, IMCI p.41)', () {
    final DateTime born = DateTime(2027, 1, 15);
    test('up to the day before two months', () {
      expect(HealthGuidance.isYoungInfant(born, DateTime(2027, 3, 14, 23)),
          isTrue);
      expect(
          HealthGuidance.isYoungInfant(born, DateTime(2027, 3, 15)), isFalse);
      expect(HealthGuidance.isYoungInfant(null, DateTime(2027)), isFalse);
    });
    test('fever or below 35.5 °C is urgent', () {
      expect(
          HealthGuidance.forTemperature(37.5, TemperatureMethod.armpit,
              youngInfant: true),
          CareLevel.urgent);
      expect(
          HealthGuidance.forTemperature(35.4, TemperatureMethod.armpit,
              youngInfant: true),
          CareLevel.urgent);
      expect(
          HealthGuidance.forTemperature(36.8, TemperatureMethod.armpit,
              youngInfant: true),
          CareLevel.none);
    });
    test('the young-infant signs are urgent only for a young infant', () {
      for (final HealthSymptom s in HealthGuidance.youngInfantSigns) {
        expect(
            HealthGuidance.forSymptoms(<HealthSymptom>[s], youngInfant: true),
            CareLevel.urgent,
            reason: s.name);
      }
      expect(
          HealthGuidance.forSymptoms(<HealthSymptom>[HealthSymptom.feelsCold],
              youngInfant: false),
          CareLevel.none);
    });
  });

  group('older child', () {
    test('fever: see a health worker, not urgent', () {
      expect(
          HealthGuidance.forTemperature(38.2, TemperatureMethod.armpit,
              youngInfant: false),
          CareLevel.seeHealthWorker);
    });
    test('general danger signs are urgent at any age (IMCI p.1)', () {
      expect(HealthGuidance.dangerSigns, <HealthSymptom>{
        HealthSymptom.unableToFeed,
        HealthSymptom.vomitsEverything,
        HealthSymptom.convulsions,
        HealthSymptom.lethargic,
      });
      for (final HealthSymptom s in HealthGuidance.dangerSigns) {
        expect(
            HealthGuidance.forSymptoms(<HealthSymptom>[s], youngInfant: false),
            CareLevel.urgent);
      }
    });
    test('return-immediately signs (IMCI p.39)', () {
      for (final HealthSymptom s in HealthGuidance.returnSigns) {
        expect(
            HealthGuidance.forSymptoms(<HealthSymptom>[s], youngInfant: false),
            CareLevel.seeHealthWorker,
            reason: s.name);
      }
    });
    test('everyday signs carry no message', () {
      expect(
          HealthGuidance.forSymptoms(<HealthSymptom>[
            HealthSymptom.cough,
            HealthSymptom.runnyNose,
            HealthSymptom.injectionSite,
            HealthSymptom.crying,
          ], youngInfant: false),
          CareLevel.none);
    });
  });

  test('names round-trip', () {
    for (final HealthSymptom s in HealthSymptom.values) {
      expect(HealthSymptom.fromName(s.name), s);
    }
    expect(HealthSymptom.fromName('nonsense'), isNull);
  });
}
