class StorageKey {
  static const String isLoginKey = "isLogin";
  static const String isDarkModeKey = "isDarkMode";
  static const String languageKey = "language";
  static const String uidKey = "uid";

  /// Child's name, cached locally so reminders can be built on app start
  /// without a Firestore read (and so they still work offline).
  static const String userNameKey = "userName";

  /// Set once the first-launch introduction has been seen or skipped.
  static const String hasSeenOnboardingKey = "hasSeenOnboarding";

  /// Preferences that belong to the device, not to whoever is signed in.
  /// They survive logout and account deletion: a parent who signs out
  /// should not see the introduction again or lose their language.
  static const Set<String> devicePreferences = <String>{
    isDarkModeKey,
    languageKey,
    hasSeenOnboardingKey,
  };
}
