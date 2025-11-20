import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/utils/apiEndpoints.dart';

Future CreateOrderProduction({
  required String branchId,
  required String productId,
  required String package,
  required double qty,
  required String ordername
}) async {
  final url = Uri.parse(Apiendpoints.baseUrl+Apiendpoints.orderProduction.add);

  final Map<String, dynamic> requestBody = {
    "branch": branchId,
    "product": productId,
    "package": package,
    "qty": qty,
    "ordername":ordername
  };

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(requestBody),
    ).timeout(Duration(minutes: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ الطلب تم بنجاح:");
      print(jsonDecode(response.body));
    } else {
      print("❌ فشل الطلب: ${response.statusCode}");
      print(response.body);
    }
  } catch (e) {
    print("⚠️ خطأ في الإرسال: $e");
  }
}
