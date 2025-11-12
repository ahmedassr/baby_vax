import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';
import 'package:baby_vax/app/core/values/app_enum/medical_date_state_enum.dart';

class MedicalDatesGenerator {
  static List<MedicalDatesModel> generator(String birthDateStr) {
    DateTime birthDate = DateTime.parse(birthDateStr);
    MedicalDateStateEnum pendingState = MedicalDateStateEnum.pending;
    return [
      MedicalDatesModel(
          name: "BCG and Hepatitis B (1st dose)",
          description: "Protects against tuberculosis and hepatitis B. Given at birth.",
          date: birthDate.add(const Duration(hours: 5)).toIso8601String(),
          state: pendingState),
      MedicalDatesModel(
          name: "First DTP-HepB-Hib, Polio and Pneumococcal",
          description: "Prevents diphtheria, tetanus, whooping cough, hepatitis B, Hib, polio, and pneumonia. Given at 2 months.",
          date: birthDate.add(const Duration(days: 60)).toIso8601String(),
          state: pendingState),
      MedicalDatesModel(
          name: "Second DTP-HepB-Hib, Polio and Pneumococcal",
          description: "Second dose to strengthen protection. Given at 4 months.",
          date: birthDate.add(const Duration(days: 120)).toIso8601String(),
          state: pendingState),
      MedicalDatesModel(
          name: "Third DTP-HepB-Hib, Polio and Pneumococcal",
          description: "Final primary dose of early vaccines. Given at 6 months.",
          date: birthDate.add(const Duration(days: 180)).toIso8601String(),
          state: pendingState),
      MedicalDatesModel(
          name: "Measles (1st dose)",
          description: "Protects against measles. Given at 9 months.",
          date: birthDate.add(const Duration(days: 270)).toIso8601String(),
          state: pendingState),
      MedicalDatesModel(
          name: "MMR, Varicella and Pneumococcal Booster",
          description: "Protects against measles, mumps, rubella, chickenpox, and boosts pneumonia protection. Given at 12 months.",
          date: birthDate.add(const Duration(days: 350)).toIso8601String(),
          state: pendingState),
      MedicalDatesModel(
          name: "Booster DTP-HepB-Hib, Polio and MMR (2nd dose)",
          description: "Booster for earlier vaccines and second dose of MMR. Given at 18 months.",
          date: birthDate.add(const Duration(days: 540)).toIso8601String(),
          state: pendingState),
      MedicalDatesModel(
          name: "School Entry Boosters: DTP + Polio + Varicella (2nd dose)",
          description: "Boosters to protect before school: diphtheria, tetanus, polio, chickenpox. Given around 5 years.",
          date: birthDate.add(const Duration(days: 5*365)).toIso8601String(),
          state: pendingState),
      MedicalDatesModel(
          name: "HPV Vaccine",
          description: "Protects against human papillomavirus. Given at age 10–12, mostly for girls (sometimes boys).",
          date: birthDate.add(const Duration(days: 11*365)).toIso8601String(),
          state: pendingState),
      MedicalDatesModel(
          name: "Td Booster (Tetanus & Diphtheria)",
          description: "Teenage booster for tetanus and diphtheria. Given at age 15.",
          date: birthDate.add(const Duration(days: 15*365)).toIso8601String(),
          state: pendingState),
    ];
  }
}
