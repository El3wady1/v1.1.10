import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Unitss {
  static Future<void> fetchAndCacheUnits() async {
    final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.unit.getall);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'];

        // تحويل كل عنصر إلى JSON string
        final List<String> stringList = List<String>.from(
          data.map((item) => json.encode(item)),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('cached_units', stringList);
      } else {
        print('Failed to load Units: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  static Future<List<dynamic>> loadCachedUnits() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getStringList('cached_units');

    if (cachedData != null) {
      return cachedData.map((item) => json.decode(item)).toList();
    } else {
      return [];
    }
  }
}
