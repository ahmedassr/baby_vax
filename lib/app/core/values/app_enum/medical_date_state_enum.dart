enum MedicalDateStateEnum {
  pending,
  completed,
  skipped,
}

extension MedicalDateStateEnumEx on MedicalDateStateEnum {
  String get label {
    switch (this) {
      case MedicalDateStateEnum.pending:
        return "Pending";
      case MedicalDateStateEnum.completed:
        return "Completed";
      case MedicalDateStateEnum.skipped:
        return "Skipped";
    }
  }
}
