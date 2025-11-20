import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future getAllSupplierServices() async {
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
      return data["data"];
    } else {
      throw Exception('فشل في تحميل البيانات، : ${response.statusCode}');
    }
  } catch (e) {
       final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cached_suppliers');
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }
   // throw Exception("فشل في جلب بيانات المستخدم: $e");
  }

