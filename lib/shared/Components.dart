import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

Widget defaultFormField(
    {required controller,
    required TextInputType keyboardType,
    FormFieldValidator? validator,
    Color borderColor = Colors.white,
    Color iconColor = Colors.grey,
    Color labelColor = Colors.black,
    String? hint,
    int? minLine,
    String? label,
    IconData? prefixIcon,
    ValueChanged? onSubmit}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    validator: validator,
    onFieldSubmitted: onSubmit,
    minLines: minLine,
    maxLines: (minLine ?? 0) + 1,
    decoration: InputDecoration(
      hintText: hint,
      label: Text(
        label ?? '',
        style: TextStyle(color: labelColor),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: iconColor,
      ),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(width: 2, color: borderColor)),
    ),
  );
}

Future myNavigator(BuildContext context, Widget nextPage,
    {bool backButton = false}) {
  if (backButton) {
    return Navigator.push(
        context, MaterialPageRoute(builder: (context) => nextPage));
  } else {
    return Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => nextPage));
  }
}

Widget passwordFormField(
    {required controller,
    required bool isVisible,
    required VoidCallback suffixIconOnPressed,
    FormFieldValidator? validator,
    Color iconColor = Colors.grey,
    Color borderColor = Colors.white,
    String? hint,
    String? label,
    Color labelColor = Colors.black,
    MaterialColor? focusColor,
    ValueChanged? onSubmit}) {
  return TextFormField(
    controller: controller,
    keyboardType: TextInputType.visiblePassword,
    obscureText: !isVisible,
    validator: validator,
    onFieldSubmitted: onSubmit,
    decoration: InputDecoration(
        hintText: hint,
        label: Text(
          label ?? '',
          style: TextStyle(color: labelColor, fontSize: 22),
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(width: 2, color: borderColor)),
        prefixIcon: Icon(
          Icons.lock,
          color: iconColor,
        ),
        suffixIcon: IconButton(
          onPressed: suffixIconOnPressed,
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
        )),
  );
}

Widget defaultButton(
    {required double width,
    required Color background,
    Color textColor = Colors.black,
    required double radius,
    required VoidCallback onPressed,
    required Widget child}) {
  return Container(
    width: width,
    height: 50,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: MaterialButton(
      onPressed: onPressed,
      child: child,
    ),
  );
}

Future<bool?> myToast({
  required String msg,
  MaterialColor background = Colors.red,
  Toast showLength = Toast.LENGTH_SHORT,
  int timeInIosWeb = 1,
}) {
  return Fluttertoast.showToast(
      msg: msg ?? '',
      toastLength: showLength,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: timeInIosWeb,
      backgroundColor: background,
      textColor: Colors.white,
      fontSize: 16.0);
}

Widget customSearchBar({
  required hint,
  required TextEditingController controller,
  required Function(String) onChange,
  required String? Function(String?)? validate,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: TextFormField(
            controller: controller,
            onChanged: onChange,
            validator: validate,
            enabled: true,
            keyboardType: TextInputType.name,
            decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                label: Text(hint),
                border: InputBorder.none),
          )),
    ),
  );
}

Widget CustomBoldText(
    {required String title,
    required double size,
    required Color background,
    int? maxLines,
    TextAlign textAlign = TextAlign.start,
    FontWeight? fontWeight}) {
  return Text(title,
      maxLines: maxLines,
      textAlign: TextAlign.start,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
          fontSize: size,
          fontWeight: fontWeight ?? FontWeight.w800,
          color: background));
}

Widget myDivider() => Padding(
      padding: const EdgeInsetsDirectional.only(
          start: 20.0, top: 10, bottom: 10, end: 20),
      child: Container(
        width: double.infinity,
        height: 2.0,
        color: Colors.grey[300],
      ),
    );

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> myMsg(
    {required BuildContext context,
    required String content,
    Color background = Colors.yellow}) {
  return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(
      content,
      textAlign: TextAlign.center,
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: background,
  ));
}
