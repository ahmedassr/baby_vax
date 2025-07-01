import 'package:baby_vax/app/core/imports/import_manger.dart';

class ArgumentService extends GetxService {
  late dynamic _argument;

  void setArgument(dynamic args) {
    _argument = args;
  }

  T getArguments<T>() {
    return _argument as T;
  }

  void clearArguments() {
    _argument = null;
  }
}
