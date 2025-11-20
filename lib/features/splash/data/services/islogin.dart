import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

Future Islogin<String>() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
 // var tokenvalue =await prefs.getString(Userthing.token);
  //return tokenvalue;
}

Future IsloginAsPaent<String>() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  //var tokenvalue =await prefs.getString(Adminthing.token_Admin);
  //return tokenvalue;
}
