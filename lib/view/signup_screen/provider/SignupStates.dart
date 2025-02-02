class SignupStates {
  final bool dateSelected;
  final bool success;
  final bool isLoading;
  final bool isVisible;
  final bool dataIsSelected;
  final String? error;
  final bool? isNext;

  SignupStates({this.dateSelected = false,
    this.isLoading = false,
    this.success = false,
    this.isVisible = false,
    this.isNext = false,
    this.dataIsSelected = false,
    this.error});

  SignupStates copyWith({bool? dateSelected,
    bool? success,
    bool? isLoading,
    bool? isVisible,
    bool? isNext,
    bool? dataIsSelected,
    String? error}) {
    return SignupStates(
        dateSelected: dateSelected ?? this.dateSelected,
        success: success ?? this.success,
        isLoading: isLoading ?? this.isLoading,
        isVisible: isVisible ?? this.isVisible,
        isNext: isNext ?? this.isNext,
        dataIsSelected: dataIsSelected ?? this.dataIsSelected,
        error: error ?? this.error);
  }
}
