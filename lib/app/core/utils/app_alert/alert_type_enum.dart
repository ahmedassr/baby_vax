import 'package:baby_vax/app/core/imports/import_library.dart';

enum AlertType{
error,
fieldRequired,
success,
attention,
customWithSingleAction,
yesOrNo,
customWithThirdAction;

String get title{
switch(this){
  case AlertType.error :
    return "error".tr;
  case AlertType.attention :
    return "attention".tr;
  case AlertType.success :
    return "success".tr;
  case AlertType.fieldRequired :
    return "error".tr;
  case AlertType.yesOrNo :
    return "";
  case AlertType.customWithSingleAction:
    return "";
  case AlertType.customWithThirdAction:
    return "";
}
}

String get image{
  switch (this){
    case AlertType.error:
      return "";
    case AlertType.fieldRequired:
      return "";
    case AlertType.success:
      return "";
    case AlertType.attention:
      return "";
    case AlertType.customWithSingleAction:
      return "";
    case AlertType.yesOrNo:
      return "";
    case AlertType.customWithThirdAction:
      return "";
  }
}
}