import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/apiEndpoints.dart';

Future<void> addQuantityAndExpiryDate({
  required double qty,
  required String bracode,
  required String expireDate,
  required double priceIN,
}) async {
  final url = Uri.parse("${Apiendpoints.baseUrl + Apiendpoints.product.addqtyAndexpired}");

  final Map<String, dynamic> body = {
    "bracode": bracode,
    "quantity": qty??0,
    "expireDate": expireDate,
    "price":priceIN
  };

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ تمت الإضافة بنجاح: ${response.body}");
    } else {
      print("❌ فشل الإضافة: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    print("⚠️ خطأ في الاتصال: $e");
  }
}
