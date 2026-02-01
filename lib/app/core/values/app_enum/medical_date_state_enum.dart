enum MedicalDateStateEnum {
  pending("Pending"),
  completed("Completed"),
  skipped("Skipped");

  final String label;

  const MedicalDateStateEnum(this.label);

  static MedicalDateStateEnum fromLabel(String? value) {
    return MedicalDateStateEnum.values.firstWhere(
        (e) => e.label.toLowerCase() == value?.toLowerCase(),
        orElse: () => MedicalDateStateEnum.skipped);
  }
}
