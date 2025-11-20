import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<dynamic>?> getAllUnitINServices() async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.unit.getall);

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final units = data['data'];

      // تحويل قائمة الوحدات إلى List<String> باستخدام json.encode لكل عنصر
      final prefs = await SharedPreferences.getInstance();
      final stringList = units.map((unit) => json.encode(unit)).toList().cast<String>();
      await prefs.setStringList('cached_units', stringList);

      return units;
    } else {
      // محاولة جلب البيانات من الكاش
      final prefs = await SharedPreferences.getInstance();
      final cachedList = prefs.getStringList('cached_units');
      if (cachedList != null) {
        return cachedList.map((e) => json.decode(e)).toList();
      }
      return null;
    }
  } catch (e) {
    // في حالة وجود خطأ في الاتصال، جلب الكاش
    final prefs = await SharedPreferences.getInstance();
    final cachedList = prefs.getStringList('cached_units');
    if (cachedList != null) {
      return cachedList.map((e) => json.decode(e)).toList();
    }
    return null;
  }
}
