import 'package:saladafactory/core/utils/localls.dart';
import 'package:saladafactory/features/profile/data/services/getUserProfileService.dart';

class Getuserprofilerepo {
  static Future<Map<String, dynamic>> featchData() async {
    var token = await Localls.getToken();

    print("Localls Token : $token");

    final userData = await GetUserProfileService(token: "$token");

    return userData;
  }
}
