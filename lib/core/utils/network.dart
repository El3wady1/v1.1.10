// lib/core/utils/network_utils.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class NetworkUtils {
  /// فحص إذا كان هناك اتصال فعلي بالإنترنت
  static Future<bool> checkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    return await InternetConnectionChecker().hasConnection;
  }
}

