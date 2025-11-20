import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';


class Serv{
  
static Future SearchProductByBarcode({
  required String barcode,
  required BuildContext context,
}) async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.product.getByBarcode);

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"bracode": barcode}), // تأكد من صحة الاسم
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> product = data['data'] ?? data;

      showTrueSnackBar(
        context: context,
        message: "هذا المنتج موجود بالفعل",
        icon: Icons.check_circle,
      );

      print("البيانات المستلمة من السيرفر: $product");
      return product;
    } else {
      showfalseSnackBar(
        context: context,
        message: "هذا المنتج غير مسجل",
        icon: Icons.error,
      );
      return null;
    }
  } catch (e) {
    print("حدث خطأ أثناء الاتصال بالسيرفر: $e");
    return null;
  }
}

}