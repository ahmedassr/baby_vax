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
    return "Error";
  case AlertType.attention :
    return "Attention";
  case AlertType.success :
    return "Success";
  case AlertType.fieldRequired :
    return "Error";
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