import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductsS {
  static Future<void> fetchAndCacheProducts() async {
    final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.product.getAll);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final List<dynamic> data = jsonBody['data'];

        // Convert to List<String>
        final List<String> stringList = data.map((item) => json.encode(item)).toList();

        // Cache it
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('cached_Products', stringList);
      } else {
        print('Failed to load Products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadCachedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getStringList('cached_Products');

    if (cachedData != null) {
      return cachedData.map((item) => json.decode(item) as Map<String, dynamic>).toList();
    } else {
      return [];
    }
  }
}
