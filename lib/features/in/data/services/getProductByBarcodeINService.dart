import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';

Future<void> cacheProductsList(List<String> products) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('cached_Products', products);
}

Future getProductByBarcodeINService({
  required String barbracode,
  required BuildContext context,
}) async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.product.getByBarcode);

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"bracode": barbracode}),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> product = data;

      // تحويل المنتج إلى JSON وتخزينه في الكاش
      final List<String> productStrings = [jsonEncode(product)];
      await cacheProductsList(productStrings);

      showTrueSnackBar(
        context: context,
        message: "هذا المنتج موجود بالفعل",
        icon: Icons.check_circle,
      );

      print("البيانات المستلمة من السيرفر: ${data["data"]}");

      // إرجاع المنتج داخل قائمة
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

//   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final List<String>? cachedList = prefs.getStringList('cached_Products');

  //   if (cachedList != null) {
  //     try {
  //       // تحويل كل عنصر من String إلى Map
  //       final List<Map<String, dynamic>> cachedProducts =
  //           cachedList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

  //       final matchedItem = cachedProducts.firstWhere(
  //         (item) => item['bracode'] == barbracode,
  //         orElse: () => {},
  //       );

  //       if (matchedItem.isNotEmpty) {
  //         showTrueSnackBar(
  //           context: context,
  //           message: "تم العثور على المنتج من الكاش",
  //           icon: Icons.storage,
  //         );
  //         print("المنتج من الكاش: $matchedItem");
  //         return matchedItem;
  //       } else {
  //         showfalseSnackBar(
  //           context: context,
  //           message: "الباركود غير موجود في الكاش",
  //           icon: Icons.warning,
  //         );
  //         return null;
  //       }
  //     } catch (e) {
  //       print("فشل فك JSON من الكاش: $e");
  //       showfalseSnackBar(
  //         context: context,
  //         message: "لا يمكن قراءة البيانات من الكاش",
  //         icon: Icons.error,
  //       );
  //       return null;
  //     }
  //   } else {
  //     showfalseSnackBar(
  //       context: context,
  //       message: "لا يوجد اتصال بالانترنت ولا بيانات مخزنة",
  //       icon: Icons.cloud_off,
  //     );
  //     return null;
  //   }    return null;
  }
}
