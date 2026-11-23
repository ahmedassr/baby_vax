import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Chart colours, as a [ThemeExtension] (polish §1.6).
///
/// The growth chart, the temperature chart and the milestone bar read these
/// instead of picking scheme roles, so every chart draws the baby's readings,
/// the WHO reference, alerts and markers in the same colours. Each series
/// also differs in shape (solid line, dashed line, band, diamond), so no
/// chart relies on colour alone.
@immutable
class AppChartColors extends ThemeExtension<AppChartColors> {
  const AppChartColors({
    required this.series,
    required this.reference,
    required this.referenceBand,
    required this.alert,
    required this.marker,
    required this.event,
    required this.grid,
    required this.ink,
  });

  static const AppChartColors light = AppChartColors(
    series: AppPalette.p40,
    reference: AppPalette.i40,
    referenceBand: Color(0x2E006689), // i40 at 18%
    alert: AppPalette.e40,
    marker: AppPalette.w40,
    event: AppPalette.i40,
    grid: AppPalette.nv90,
    ink: AppPalette.nv30,
  );

  static const AppChartColors dark = AppChartColors(
    series: AppPalette.pd80,
    reference: AppPalette.i80,
    referenceBand: Color(0x337ED0FC), // i80 at 20%
    alert: AppPalette.e80,
    marker: AppPalette.w80,
    event: AppPalette.i80,
    grid: AppPalette.nv30,
    ink: AppPalette.nv80,
  );

  /// The baby's own readings: line and points.
  final Color series;

  /// The WHO average line.
  final Color reference;

  /// The WHO "most babies" band (translucent, drawn under everything).
  final Color referenceBand;

  /// The fever line and readings outside the reference band.
  final Color alert;

  /// Medicine markers.
  final Color marker;

  /// Dose (vaccination) markers.
  final Color event;

  final Color grid;

  /// Axis labels and ticks.
  final Color ink;

  /// The extension from [context], falling back to the set for the current
  /// brightness if the theme does not carry one.
  static AppChartColors of(BuildContext context) =>
      Theme.of(context).extension<AppChartColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  AppChartColors copyWith({
    Color? series,
    Color? reference,
    Color? referenceBand,
    Color? alert,
    Color? marker,
    Color? event,
    Color? grid,
    Color? ink,
  }) =>
      AppChartColors(
        series: series ?? this.series,
        reference: reference ?? this.reference,
        referenceBand: referenceBand ?? this.referenceBand,
        alert: alert ?? this.alert,
        marker: marker ?? this.marker,
        event: event ?? this.event,
        grid: grid ?? this.grid,
        ink: ink ?? this.ink,
      );

  @override
  AppChartColors lerp(ThemeExtension<AppChartColors>? other, double t) {
    if (other is! AppChartColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppChartColors(
      series: mix(series, other.series),
      reference: mix(reference, other.reference),
      referenceBand: mix(referenceBand, other.referenceBand),
      alert: mix(alert, other.alert),
      marker: mix(marker, other.marker),
      event: mix(event, other.event),
      grid: mix(grid, other.grid),
      ink: mix(ink, other.ink),
    );
  }
}
