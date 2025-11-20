import 'package:saladafactory/core/utils/localls.dart';
import 'package:saladafactory/features/home/data/services/ReturnLastloginService.dart';

class ReturnLastloginRepo {
  static Future featchData() async {
    var token = await Localls.getToken();

    print("Localls Token : $token");

    final userData = await GetReturnLastlogin(token: "$token");

    return userData;
  }
}
