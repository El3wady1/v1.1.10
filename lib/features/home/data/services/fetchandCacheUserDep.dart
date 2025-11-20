import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/Strings.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDepartment {
  // ✅ تحميل الأقسام وتخزين الـ Map كاملة في SharedPreferences بصيغة JSON
  static Future<void> fetchAndCacheUserDep() async {
    final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.auth.userDep);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Strings.tokenKey);

      if (token == null) {
        print('Token غير موجود');
        return;
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final List<dynamic> data = jsonBody['data'];

        // تحويل القائمة إلى JSON String وتخزينها
        final String jsonString = jsonEncode(data);
        await prefs.setString('cached_userDep_full', jsonString);

        print('✅ تم تخزين الأقسام كاملة بنجاح');
      } else {
        print('❌ فشل تحميل البيانات: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ أثناء التحميل: $e');
    }
  }

  // ✅ استرجاع الأقسام كـ List<Map<String, dynamic>>
  static Future<List<Map<String, dynamic>>> loadCachedUserDep() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('cached_userDep_full');

    if (jsonString != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(jsonString);
        final List<Map<String, dynamic>> departments =
            decodedList.cast<Map<String, dynamic>>();

        print('✅ تم الاسترجاع من الكاش: $departments');
        return departments;
      } catch (e) {
        print('❌ خطأ أثناء فك JSON: $e');
        return [];
      }
    } else {
      print('⚠️ لا توجد بيانات مخزنة');
      return [];
    }
  }
}
