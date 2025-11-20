import 'package:saladafactory/core/utils/Strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Localls {
  static Future<void> setToken({required String token}) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(Strings.tokenKey, token);
  }
 static Future<void> setrole({required String role}) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(Strings.role, role);
  }

  static Future<String?> getrole() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString(Strings.role); 
  }  
  
  static Future<String?> getToken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString(Strings.tokenKey); 
  }
    static Future setUserID({required String userId}) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString("userId",userId );
  }

  static Future<String?> getUserID() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString("userId"); 
  }

    static Future setdepatmentid({required String depatmentid}) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString("department",depatmentid );
  }

  static Future<String?> getdepartment() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString("department"); 
  }
}
