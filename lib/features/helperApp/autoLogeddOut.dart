// ---------------- Session Manager ----------------
import 'dart:async';

import 'package:saladafactory/core/utils/Strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static Timer? _timer;
  static Function? _onTimeout;

  static Future<void> startTimer(Function onTimeout) async {
    _onTimeout = onTimeout;
    _timer?.cancel();
    _timer = Timer( Duration(milliseconds: Strings.logoutTime), () async {
      await _onTimeout?.call();
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastActivity', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> resetTimer() async {
    if (_onTimeout != null) {
      await startTimer(_onTimeout!);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastActivity', DateTime.now().millisecondsSinceEpoch);
    }
  }

  static void stopTimer() {
    _timer?.cancel();
  }
}
// -------------------------------------------------
