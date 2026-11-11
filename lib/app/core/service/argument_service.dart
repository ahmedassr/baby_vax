import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Hands an object to the next screen.
///
/// Nullable since v1.1: v1.0 kept it in a `late` field, so opening a screen
/// whose argument had not been set (a deep link, a test, a restored route)
/// threw a LateInitializationError instead of showing the screen's
/// "missing" state.
class ArgumentService extends GetxService {
  dynamic _argument;

  void setArgument(dynamic args) {
    _argument = args;
  }

  /// The argument if it is a [T], otherwise null.
  T? getArguments<T>() {
    final dynamic a = _argument;
    return a is T ? a : null;
  }

  void clearArguments() {
    _argument = null;
  }
}
