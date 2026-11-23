/// What the Health log may say about a temperature or a set of signs.
///
/// Every number and every list below comes from the WHO Integrated
/// Management of Childhood Illness (IMCI) Chart Booklet, March 2014,
/// downloaded in the v1.1 session on 15 November 2026 (SHA-256
/// d10fd1d0…a8a6959f); page numbers are the booklet's own "Page n of 76".
/// See docs/THIRD_PARTY.md. Nothing here is a diagnosis or advice on
/// treatment: it only decides which of WHO's "get help" messages to show.
library;

/// How the temperature was taken. IMCI's figures are for the armpit and
/// give rectal readings as about 0.5 °C higher; for other methods WHO gives
/// no figure, so the app does not judge them.
enum TemperatureMethod { armpit, rectal, other }

/// Signs a parent can pick when logging. Stored by [name]; the Firestore
/// rules list the same names.
enum HealthSymptom {
  feelsHot,
  feedingPoorly,
  unableToFeed,
  vomiting,
  vomitsEverything,
  diarrhoea,
  bloodInStool,
  cough,
  runnyNose,
  fastBreathing,
  difficultBreathing,
  convulsions,
  lethargic,
  lessActive,
  feelsCold,
  yellowSkin,
  rash,
  injectionSite,
  crying;

  static HealthSymptom? fromName(String? name) {
    for (final HealthSymptom s in values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// Which message to show.
enum CareLevel {
  /// Nothing WHO lists.
  none,

  /// WHO advises returning to a health worker straight away (IMCI "when to
  /// return immediately"), e.g. a fever.
  seeHealthWorker,

  /// WHO's danger signs: needs urgent care now.
  urgent,
}

class HealthGuidance {
  const HealthGuidance._();

  /// Fever: 37.5 °C or above, armpit (IMCI page 4 and its footnote).
  static const double feverArmpitC = 37.5;

  /// Rectal readings are about 0.5 °C higher (IMCI page 4 footnote).
  static const double rectalOffsetC = 0.5;

  /// Young infant: below 35.5 °C, armpit, is a danger sign (IMCI page 41).
  static const double lowArmpitC = 35.5;

  /// IMCI's "young infant" is up to 2 months old.
  static const int youngInfantMonths = 2;

  /// Whether a child born on [birth] is a young infant on [on].
  static bool isYoungInfant(DateTime? birth, DateTime on) {
    if (birth == null) return false;
    final DateTime twoMonths =
        DateTime(birth.year, birth.month + youngInfantMonths, birth.day);
    return on.isBefore(twoMonths);
  }

  static double? _offset(TemperatureMethod m) => switch (m) {
        TemperatureMethod.armpit => 0,
        TemperatureMethod.rectal => rectalOffsetC,
        TemperatureMethod.other => null,
      };

  /// True or false for armpit and rectal readings; null when WHO gives no
  /// figure for the method.
  static bool? isFever(double celsius, TemperatureMethod method) {
    final double? o = _offset(method);
    return o == null ? null : celsius >= feverArmpitC + o;
  }

  /// Below WHO's low-temperature figure (a danger sign in young infants).
  static bool? isLow(double celsius, TemperatureMethod method) {
    final double? o = _offset(method);
    return o == null ? null : celsius < lowArmpitC + o;
  }

  /// IMCI general danger signs, any age (page 1): not able to drink or
  /// breastfeed, vomits everything, convulsions, lethargic or unconscious.
  static const Set<HealthSymptom> dangerSigns = <HealthSymptom>{
    HealthSymptom.unableToFeed,
    HealthSymptom.vomitsEverything,
    HealthSymptom.convulsions,
    HealthSymptom.lethargic,
  };

  /// Young infant, up to 2 months (pages 41 and 51): not feeding well,
  /// fast or difficult breathing, fever, feels unusually cold, reduced
  /// activity, palms and soles yellow.
  static const Set<HealthSymptom> youngInfantSigns = <HealthSymptom>{
    HealthSymptom.feelsHot,
    HealthSymptom.feedingPoorly,
    HealthSymptom.fastBreathing,
    HealthSymptom.difficultBreathing,
    HealthSymptom.feelsCold,
    HealthSymptom.lessActive,
    HealthSymptom.yellowSkin,
  };

  /// "Return immediately" for a sick child (page 39): develops a fever,
  /// fast or difficult breathing, blood in stool, drinking poorly.
  static const Set<HealthSymptom> returnSigns = <HealthSymptom>{
    HealthSymptom.feelsHot,
    HealthSymptom.fastBreathing,
    HealthSymptom.difficultBreathing,
    HealthSymptom.bloodInStool,
    HealthSymptom.feedingPoorly,
  };

  static CareLevel forSymptoms(Iterable<HealthSymptom> signs,
      {required bool youngInfant}) {
    final Set<HealthSymptom> s = signs.toSet();
    if (s.intersection(dangerSigns).isNotEmpty) return CareLevel.urgent;
    if (youngInfant && s.intersection(youngInfantSigns).isNotEmpty) {
      return CareLevel.urgent;
    }
    if (s.intersection(returnSigns).isNotEmpty) {
      return CareLevel.seeHealthWorker;
    }
    return CareLevel.none;
  }

  static CareLevel forTemperature(double celsius, TemperatureMethod method,
      {required bool youngInfant}) {
    final bool fever = isFever(celsius, method) ?? false;
    final bool low = isLow(celsius, method) ?? false;
    if (youngInfant && (fever || low)) return CareLevel.urgent;
    if (fever) return CareLevel.seeHealthWorker;
    return CareLevel.none;
  }

  /// The more serious of two levels.
  static CareLevel max(CareLevel a, CareLevel b) => a.index >= b.index ? a : b;
}
