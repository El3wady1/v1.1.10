import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/apiEndpoints.dart';

Future subtractProductQuantity({
  required String barcode,
  required double quantityToSubtract,
}) async {
  final url = Uri.parse(
    Apiendpoints.baseUrl+Apiendpoints.product.outproduct
  ); // غيّر الـ localhost إذا كنت تستخدمه من الهاتف

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
  
      },
      body: jsonEncode({
        "bracode": barcode,
        "quantityToSubtract": quantityToSubtract,
      }),
    );

    if (response.statusCode == 200||response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print("تم خصم الكمية بنجاح: $data");
    } else {
      print("فشل في خصم الكمية: ${response.statusCode}");
      print("الرد: ${response.body}");
    }
  } catch (e) {
    print("خطأ في الاتصال بالسيرفر: $e");
  }
}
