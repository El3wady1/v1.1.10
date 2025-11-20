import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<dynamic>?> getAllSupplierINServices() async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.supplier.getall);

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final suppliers = data["data"];

      // تحويل كل عنصر إلى String وتخزينه
      final prefs = await SharedPreferences.getInstance();
      final encodedList = suppliers.map<String>((item) => json.encode(item)).toList();
      await prefs.setStringList('cached_suppliers', encodedList);

      return suppliers;
    } else {
      // فشل الاتصال => استخدم البيانات المخزنة
      return await _getCachedSuppliers();
    }
  } catch (e) {
    // عند حصول خطأ => استخدم البيانات المخزنة
    return await _getCachedSuppliers();
  }
}

Future<List<dynamic>?> _getCachedSuppliers() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = prefs.getStringList('cached_suppliers');
  if (jsonList != null) {
    return jsonList.map((item) => json.decode(item)).toList();
  }
  return null;
}
