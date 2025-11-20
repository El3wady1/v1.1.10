import 'dart:convert';
import 'package:saladafactory/core/utils/Strings.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import "package:http/http.dart" as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<List<Map<String, dynamic>>> getUserDepartmentServices() async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.auth.userDep);
  final prefs = await SharedPreferences.getInstance();

  try {
    final token = prefs.getString(Strings.tokenKey);
    if (token == null) throw Exception('Token غير موجود');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final List<dynamic> departmentsData = data["data"];

      // نحفظ الأقسام كاملة كـ JSON
      final String encoded = jsonEncode(departmentsData);
      await prefs.setString('cached_userDep', encoded);
print("onlin es :::$departmentsData");
      return departmentsData.cast<Map<String, dynamic>>();
    } else {
      throw Exception('فشل في تحميل البيانات: ${response.statusCode}');
    }
  } catch (e) {
    // محاولة قراءة الأقسام من الكاش
    final cachedString = prefs.getString('cached_userDep');
    if (cachedString != null) {
      final List<dynamic> cachedList = jsonDecode(cachedString);
      return cachedList.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }
}
