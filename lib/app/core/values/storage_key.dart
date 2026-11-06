class StorageKey {
  static const String isLoginKey = "isLogin";
  static const String isDarkModeKey = "isDarkMode";
  static const String languageKey = "language";
  static const String uidKey = "uid";

  /// Child's name, cached locally so reminders can be built on app start
  /// without a Firestore read (and so they still work offline).
  static const String userNameKey = "userName";
}
