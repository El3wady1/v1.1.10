import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/app_router.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/features/out/data/services/getAllSupplierServices.dart';
import 'package:saladafactory/features/out/data/services/getUserDepartment.dart';
import 'package:saladafactory/features/out/presentation/view/widget/outBodyView.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future getProductByBarCodeOUT({
  required String barbracode,
  required BuildContext context,
}) async {
  final url = Uri.parse(
    Apiendpoints.baseUrl + Apiendpoints.product.getByBarcode,
  );

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bracode": barbracode,
      }),
    );

    final decodedData = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      showTrueSnackBar(
        context: context,
        message: "هذا المنتج موجود بالفعل",
        icon: Icons.check_circle,
      );

      final List<Map<String, dynamic>> userDepartments = await getUserDepartmentServices();

      Routting.pushreplaced(
        context,
        Outbodyview(
    //       barcode: barbracode,
    //       name: decodedData["data"]["name"] ?? "",
    // availableQuantity: parseToDouble(decodedData["data"]["availableQuantity"]),
    //       unit: decodedData["data"]["unit"]["name"] ?? "لا يوجد الان",
    //       supplierAccepted:
    //           decodedData["data"]["supplierAccepted"]["name"] ?? "لا يوجد الان",
    //       department: userDepartments,
    //       productiD: decodedData["data"]["_id"] ?? "لا يوجد الان",
    //       updatedAt: decodedData["data"]["updatedAt"],
    //       unitID: decodedData["data"]["unit"]["_id"], mainProduct: decodedData["mainProduct"]['name'],  expireddate:decodedData["updated"].last["expireDate"],
         ),
      );

      print("✅ البيانات المستلمة: $decodedData");
      return decodedData;
    } else {
      print("❌ الاستجابة من السيرفر: ${response.body}");

      showfalseSnackBar(
        context: context,
        message: "هذا المنتج غير مسجل",
        icon: Icons.error,
      );

      Routting.popNoRoute(context);
    }
  } catch (e) {
    print("⚠️ swdsdsdحدث خطأ أثناء الاتصال بالسيرفر: $e");

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? cachedList = prefs.getStringList('cached_Products');

    if (cachedList != null) {
      try {
      final List<Map<String, dynamic>> cachedProducts =
            cachedList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

        final matchedItem = cachedProducts.firstWhere(
          (item) => item['bracode'] == barbracode,
          orElse: () => {},
        );

        showTrueSnackBar(
          context: context,
          message: "تم العثور على المنتج من الكاش",
          icon: Icons.storage,
        );

        final List<Map<String, dynamic>> userDepartments = await getUserDepartmentServices();

        Routting.pushreplaced(
          context,
          Outbodyview(
            // barcode: barbracode,
            // name: matchedItem["name"] ?? "",
            // availableQuantity: parseToDouble(matchedItem["availableQuantity"]) ?? 0,
            // unit: matchedItem["unit"]["name"] ?? "لا يوجد الان",
            // supplierAccepted:
            //     matchedItem["supplierAccepted"]["name"] ?? "لا يوجد الان",
            // department: userDepartments,
            // productiD: matchedItem["_id"] ?? "لا يوجد الان",
            // updatedAt: matchedItem["updatedAt"],
            // unitID: matchedItem["unit"]["_id"], mainProduct:matchedItem["mainProduct"]['name'],  expireddate:matchedItem["updated"].last["expireDate"] ,
          ),
        );

        print("✅ المنتج من الكاش: $matchedItem");
        return matchedItem;
            } catch (e) {
        print("❌ فشل فك JSON من الكاش: $e");
        showfalseSnackBar(
          context: context,
          message: "لا يمكن قراءة البيانات من الكاش",
          icon: Icons.error,
        );
        return null;
      }
    } else {
      showfalseSnackBar(
        context: context,
        message: "لا يوجد اتصال بالانترنت ولا بيانات مخزنة",
        icon: Icons.cloud_off,
      );
      return null;
    }
  }
}
double parseToDouble(dynamic value) {
  if (value == null) return 0.0;

  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (_) {
      return 0.0;
    }
  }

  return 0.0;
}
