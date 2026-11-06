import 'package:baby_vax/app/core/imports/import_library.dart';

import 'alert_type_enum.dart';

class AlertModel {
  final AlertType type;
  final String? message;
  final String? title;
  final String? imagePath;
  final String? yesButtonText;
  final String? noButtonText;
  final VoidCallback? yesAction;
  final VoidCallback? noAction;

  // There was a third "additional" button here, plumbed through to
  // AlertWidget, but no factory ever set it, so it could never render.
  // Removed along with its branch in AlertWidget rather than kept as an
  // unreachable parameter.
  AlertModel._({
    required this.type,
    this.title,
    this.message,
    this.imagePath,
    this.yesButtonText,
    this.noButtonText,
    this.yesAction,
    this.noAction,
  });

  factory AlertModel.error(
          {required String message, VoidCallback? yesAction}) =>
      AlertModel._(
          type: AlertType.error,
          title: AlertType.error.title,
          message: message,
          yesAction: yesAction);

  factory AlertModel.success(
          {required String message, VoidCallback? yesAction}) =>
      AlertModel._(
          type: AlertType.success,
          title: AlertType.success.title,
          message: message,
          yesAction: yesAction);

  factory AlertModel.fieldRequired(
          {required String fieldName, VoidCallback? yesAction}) =>
      AlertModel._(
          type: AlertType.fieldRequired,
          title: AlertType.fieldRequired.title,
          message: "$fieldName is missing.",
          yesAction: yesAction);

  factory AlertModel.attention(
          {required String message,
          VoidCallback? yesAction,
          VoidCallback? noAction}) =>
      AlertModel._(
          type: AlertType.attention,
          title: AlertType.attention.title,
          message: message,
          yesAction: yesAction,
          yesButtonText: "yes".tr,
          noAction: noAction,
          noButtonText: "cancel".tr);

  factory AlertModel.yesOrNo({
    String? imagePath,
    required String title,
    required String message,
    required String yesButtonText,
    required String noButtonText,
    required VoidCallback yesAction,
    required VoidCallback noAction,
  }) =>
      AlertModel._(
          type: AlertType.yesOrNo,
          title: title,
          message: message,
          imagePath: imagePath,
          yesAction: yesAction,
          yesButtonText: yesButtonText,
          noAction: noAction,
          noButtonText: noButtonText);
}
