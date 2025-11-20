// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:saladafactory/core/Widgets/showsnackbar.dart';
// import 'package:saladafactory/core/app_router.dart';

// import '../../../../core/utils/apiEndpoints.dart';

// Future makeOUTTransaction(
//   {
//     required String productID,
//     required String type,
//     required int quantity,
//     required String userID,
//     required String unit,
//     required String department,
//     required String supplier,
//     required BuildContext context
//   }
// ) async {
//   final url = Uri.parse(Apiendpoints.baseUrl+Apiendpoints.transaction.add); // Replace with actual endpoint

//   final Map<String, dynamic> body = {
//     "productID": productID,
//     "type":type , 
//     "quantity": quantity,
//     "userID": userID,
//     "unit": unit,
//     "department": department,
//     "supplier":supplier
//   };

//   try {
//     final response = await http.post(
//       url,
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode(body),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       print("🎉Success! The server is pleased!");
//       showTrueSnackBar(context: context, message: "تمت العملية بنجاح", icon: Icons.report);
//       Routting.popNoRoute(context);
//       print("Response: ${response.body}");
//     }else if(response.body.contains("available quantity is only ")){

//             showfalseSnackBar(context: context, message:"الكمية الموجودة ليست كافية", icon: Icons.dangerous);
//     }    
//      else {
//             showfalseSnackBar(context: context, message: "فشلت العملية", icon: Icons.report);

//       print("😬 Oops! Server didn't like it. Status: ${response.statusCode}");
//       print("Response: ${response.body}");
//     }
//   } catch (e) {
//             showfalseSnackBar(context: context, message:"هناك مشكله اعد محاولة", icon: Icons.dangerous);

//     print("❌ Crash landing! Error: $e");
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saladafactory/features/out/data/services/outProductServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/app_router.dart';
import '../../../../core/utils/apiEndpoints.dart';

/// 🔌 التحقق من وجود اتصال فعلي بالإنترنت
Future<bool> hasInternet() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// 🔁 مزامنة العمليات المخزنة عند توفر الإنترنت
Future<void> syncOfflineTransactions(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final List<String> storedData = prefs.getStringList('offline_out_transactionsss') ?? [];

  List<String> remainingData = [];

  for (String item in storedData) {
    final body = jsonDecode(item);

    try {
      final response = await http.post(
        Uri.parse(Apiendpoints.baseUrl + Apiendpoints.transaction.add),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Transaction synced: ${response.body}");
      } else {
        print("❌ Failed to sync: ${response.statusCode}");
        print("❌ Response: ${response.body}");
        remainingData.add(item);
      }
    } catch (e) {
      print("⚠️ Exception during sync: $e");
      remainingData.add(item);
    }
  }

  if (remainingData.length < storedData.length) {
    showTrueSnackBar(context: context, message: "تم إرسال بعض العمليات المحفوظة", icon: Icons.sync);
  }

  await prefs.setStringList('offline_out_transactionsss', remainingData);
}

/// ✅ دالة مساعدة لتخزين العملية محلياً
Future<void> _storeTransactionLocally(Map<String, dynamic> body) async {
  final prefs = await SharedPreferences.getInstance();
  final List<String> offlineData = prefs.getStringList('offline_out_transactionsss') ?? [];
  offlineData.add(jsonEncode(body));
  await prefs.setStringList('offline_out_transactionsss', offlineData);
}

/// 📤 إرسال عملية خروج منتج، مع دعم الأوفلاين
Future<bool> makeOUTTransaction({
  required String productID,
  required String type,
  required String barcode,
  required double quantity,
  required String userID,
  required String unit,
  required String department,
  required String supplier,
  required BuildContext context,
}) async {
  final Map<String, dynamic> body = {
    "productID": productID,
    "type": type,
    "quantity": quantity,
    "userID": userID,
    "unit": unit,
    "department": department,
    "supplier": supplier
  };

  if (await hasInternet()) {
    try {
      final response = await http.post(
        Uri.parse(Apiendpoints.baseUrl + Apiendpoints.transaction.add),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showTrueSnackBar(context: context, message: "تم إرسال العملية بنجاح", icon: Icons.cloud_done);
        await subtractProductQuantity(
          barcode: barcode,
          quantityToSubtract: double.parse(quantity.toString()),
        );
        Routting.popNoRoute(context);
        return true;
      } else {
        showTrueSnackBar(context: context, message: "فشل في الإرسال، تم حفظ العملية", icon: Icons.warning);
        Routting.popNoRoute(context);
        return false;
      }
    } catch (_) {
      showTrueSnackBar(context: context, message: "خطأ أثناء الإرسال، تم حفظ العملية", icon: Icons.error_outline);
      Routting.popNoRoute(context);
      return false;
    }
  } else {
    showTrueSnackBar(context: context, message: "لا يوجد إنترنت، تم حفظ العملية", icon: Icons.cloud_off);
    Routting.popNoRoute(context);
    return false;
  }
}
