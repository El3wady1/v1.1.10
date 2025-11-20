import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
void CustomAwesomeDialog({
  required BuildContext context,
  required DialogType dialogType,
 required String title,
 required String desc,
  Function()? btnOkOnPress,
  Function()? btnCancelOnPress,
}) {
  AwesomeDialog(
    btnCancelText: "الغاء",
    btnOkText: "موافق",
    context: context,
    animType: AnimType.bottomSlide,
    dialogType: dialogType,
    title: title,
    desc: desc,
    btnCancelOnPress: btnCancelOnPress,
    btnOkOnPress: btnOkOnPress,
  )..show();
}
