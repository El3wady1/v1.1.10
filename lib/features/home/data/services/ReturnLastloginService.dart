import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future GetReturnLastlogin({required String token}) async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.auth.userData);

  try {
    final response = await http.get(
      url,
      headers: {
        'authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      SharedPreferences pref =await SharedPreferences.getInstance();
      await Localls.setrole(role: data["role"]);
      return data ;
    } else {
      throw Exception('فشل في تحميل البيانات، : ${response.statusCode}');
    }
  } catch (e) {
    print("حدث خطأ: ${e.toString()}");
    throw Exception("فشل في جلب بيانات المستخدم: $e");
  }
}
