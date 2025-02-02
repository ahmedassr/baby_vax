class LoginStates {
  final bool inLoginScreen;
  final bool isVisible;
  final bool isLoading;
  final bool success;
  final String? error;

  LoginStates(
      {this.inLoginScreen = true,
      this.isVisible = false,
      this.isLoading = false,
      this.success = false,
      this.error});

  LoginStates copyWith(
      {bool? inLoginScreen,
      bool? isVisible,
      bool? isLoading,
      bool? success,
      String? error}) {
    return LoginStates(
      inLoginScreen: inLoginScreen ?? this.inLoginScreen,
      isVisible: isVisible ?? this.isVisible,
      isLoading: isLoading ?? this.isLoading,
      success: success ?? this.success,
      error: error ?? this.error,
    );
  }
}
