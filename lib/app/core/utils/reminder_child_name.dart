import 'package:get/get.dart';

/// The child's name as shown in reminders.
///
/// It comes from the Firestore user document's `name` field. The Firebase
/// Auth displayName is never set by this app, so using it gave every
/// reminder after a login the generic fallback.
///
/// A missing or blank name gives the localized "Your baby".
String reminderChildName(String? name) {
  final String trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? 'Reminder_default_child_name'.tr : trimmed;
}
