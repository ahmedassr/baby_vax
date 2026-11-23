import 'package:flutter/material.dart';

import '../../core/values/app_enum/medical_date_state_enum.dart';
import 'app_palette.dart';

/// How a dose's status is coloured, as a [ThemeExtension].
///
/// There are four things a parent needs to tell apart at a glance:
/// completed, pending, **overdue** (a pending dose whose day has passed —
/// never a stored state, see `VaccineStatePolicy`) and skipped. v1.0 painted
/// three of them with `switch` statements inside
/// `MedicalDateStatusBadge`, mixing `Colors.green.shade700`,
/// `theme.colorScheme.error` and `AppColors.primary`, and had no colour for
/// overdue at all.
///
/// Putting the pairs in a theme extension means the chip reads
/// `Theme.of(context).extension<AppStatusColors>()` and never branches on
/// brightness.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.pendingForeground,
    required this.pendingBackground,
    required this.completedForeground,
    required this.completedBackground,
    required this.overdueForeground,
    required this.overdueBackground,
    required this.skippedForeground,
    required this.skippedBackground,
  });

  /// Light pairs, all at least 4.5:1 (plan §2.1).
  static const AppStatusColors light = AppStatusColors(
    pendingForeground: AppPalette.lightPendingFg,
    pendingBackground: AppPalette.lightPendingBg,
    completedForeground: AppPalette.lightCompletedFg,
    completedBackground: AppPalette.lightCompletedBg,
    overdueForeground: AppPalette.lightOverdueFg,
    overdueBackground: AppPalette.lightOverdueBg,
    skippedForeground: AppPalette.lightSkippedFg,
    skippedBackground: AppPalette.lightSkippedBg,
  );

  /// Dark pairs, all at least 6.7:1 (plan §2.1).
  static const AppStatusColors dark = AppStatusColors(
    pendingForeground: AppPalette.darkPendingFg,
    pendingBackground: AppPalette.darkPendingBg,
    completedForeground: AppPalette.darkCompletedFg,
    completedBackground: AppPalette.darkCompletedBg,
    overdueForeground: AppPalette.darkOverdueFg,
    overdueBackground: AppPalette.darkOverdueBg,
    skippedForeground: AppPalette.darkSkippedFg,
    skippedBackground: AppPalette.darkSkippedBg,
  );

  final Color pendingForeground;
  final Color pendingBackground;
  final Color completedForeground;
  final Color completedBackground;
  final Color overdueForeground;
  final Color overdueBackground;
  final Color skippedForeground;
  final Color skippedBackground;

  /// The extension from [context], falling back to [light] if the theme does
  /// not carry one (a bare `MaterialApp` in a widget test).
  static AppStatusColors of(BuildContext context) =>
      Theme.of(context).extension<AppStatusColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  /// Foreground and background for one display status.
  ({Color foreground, Color background}) forStatus(DoseDisplayStatus status) {
    switch (status) {
      case DoseDisplayStatus.pending:
        return (foreground: pendingForeground, background: pendingBackground);
      case DoseDisplayStatus.completed:
        return (
          foreground: completedForeground,
          background: completedBackground
        );
      case DoseDisplayStatus.overdue:
        return (foreground: overdueForeground, background: overdueBackground);
      case DoseDisplayStatus.skipped:
        return (foreground: skippedForeground, background: skippedBackground);
    }
  }

  @override
  AppStatusColors copyWith({
    Color? pendingForeground,
    Color? pendingBackground,
    Color? completedForeground,
    Color? completedBackground,
    Color? overdueForeground,
    Color? overdueBackground,
    Color? skippedForeground,
    Color? skippedBackground,
  }) {
    return AppStatusColors(
      pendingForeground: pendingForeground ?? this.pendingForeground,
      pendingBackground: pendingBackground ?? this.pendingBackground,
      completedForeground: completedForeground ?? this.completedForeground,
      completedBackground: completedBackground ?? this.completedBackground,
      overdueForeground: overdueForeground ?? this.overdueForeground,
      overdueBackground: overdueBackground ?? this.overdueBackground,
      skippedForeground: skippedForeground ?? this.skippedForeground,
      skippedBackground: skippedBackground ?? this.skippedBackground,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppStatusColors(
      pendingForeground: mix(pendingForeground, other.pendingForeground),
      pendingBackground: mix(pendingBackground, other.pendingBackground),
      completedForeground: mix(completedForeground, other.completedForeground),
      completedBackground: mix(completedBackground, other.completedBackground),
      overdueForeground: mix(overdueForeground, other.overdueForeground),
      overdueBackground: mix(overdueBackground, other.overdueBackground),
      skippedForeground: mix(skippedForeground, other.skippedForeground),
      skippedBackground: mix(skippedBackground, other.skippedBackground),
    );
  }
}

/// What the UI shows for a dose, which is not the same as what is stored.
///
/// Firestore only ever holds `Pending`, `Completed` or `Skipped` (the rules
/// allow nothing else). [DoseDisplayStatus.overdue] is how a `Pending` dose
/// whose day has passed is *displayed*; it is never written.
enum DoseDisplayStatus {
  pending,
  completed,
  overdue,
  skipped;

  /// The translation key for this status's label.
  String get translationKey => switch (this) {
        DoseDisplayStatus.pending => MedicalDateStateEnum.pending.label,
        DoseDisplayStatus.completed => MedicalDateStateEnum.completed.label,
        DoseDisplayStatus.skipped => MedicalDateStateEnum.skipped.label,
        DoseDisplayStatus.overdue => 'VaccinationTimeStatusEnum_overdue',
      };
}
