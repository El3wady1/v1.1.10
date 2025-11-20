import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupplierSS {
  static Future<void> fetchAndCacheSuppliers() async {
    final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.supplier.getall);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'];

        // تحويل العناصر إلى JSON strings
        final List<String> stringList = List<String>.from(
          data.map((item) => json.encode(item)),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('cached_suppliers', stringList);
      } else {
        print('Failed to load suppliers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  static Future<List<dynamic>> loadCachedSuppliers() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getStringList('cached_suppliers');

    if (cachedData != null) {
      // فك تشفير كل عنصر
      return cachedData.map((item) => json.decode(item)).toList();
    } else {
      return [];
    }
  }
}
