import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/apiEndpoints.dart';

Future<Map<String, dynamic>> GetUserProfileService({required String token}) async {
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
      print(data);
      return data as Map<String, dynamic>;
    } else {
      throw Exception('فشل في تحميل البيانات، الكود: ${response.statusCode}');
    }
  } catch (e) {
    print("حدث خطأ: ${e.toString()}");
    throw Exception("فشل في جلب بيانات المستخدم: $e");
  }
}
