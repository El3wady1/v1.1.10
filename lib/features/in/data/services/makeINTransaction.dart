// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:saladafactory/core/Widgets/showsnackbar.dart';
// import 'package:saladafactory/core/app_router.dart';

// import '../../../../core/utils/apiEndpoints.dart';

// Future makeINTransaction(
//     {required String productID,
//     required String type,
//     required int quantity,
//     required String userID,
//     required String unitID,
//     required String department,
//     required String supplier,
//     required BuildContext context}) async {
//   final url = Uri.parse(Apiendpoints.baseUrl +
//       Apiendpoints.transaction.add); // Replace with actual endpoint

//   final Map<String, dynamic> body = {
//     "productID": productID,
//     "type": type,
//     "quantity": quantity,
//     "userID": userID,
//     "unit": unitID,
//     "department": department,
//     "supplier": supplier
//   };

//   try {
//     final response = await http.post(
//       url,
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode(body),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       print("🎉Success! The server is pleased!");
//       showTrueSnackBar(
//           context: context, message: "تمت العملية بنجاح", icon: Icons.report);
//       Routting.popNoRoute(context);
//       print("Response: ${response.body}");
//     } else if (response.body.contains("available quantity is only ")) {
//       showfalseSnackBar(
//           context: context,
//           message: "الكمية الموجودة ليست كافية",
//           icon: Icons.dangerous);
//     } else {
//       showfalseSnackBar(
//           context: context, message: "فشلت العملية", icon: Icons.report);

//       print("😬 Oops! Server didn't like it. Status: ${response.statusCode}");
//       print("Response: ${response.body}");
//     }
//   } catch (e) {
//     showfalseSnackBar(
//         context: context,
//         message: "هناك مشكله اعد محاولة",
//         icon: Icons.dangerous);

//     print("❌ Crash landing! Error: $e");
//   }
// }

import 'dart:convert';
// import 'dart:ffi';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
const String offlineKey = 'offline_transactions';

Future<bool> sendTransaction({
  required String productID,
  required String type,
  required double quantity,
  required String userID,
  required String unitID,
  required String department,
  required String supplier,
}) async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.transaction.add);

  final Map<String, dynamic> body = {
    "productID": productID,
    "type": type,
    "quantity": quantity,
    "userID": userID,
    "unit": unitID,
    "department": department,
    "supplier": supplier,
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print("Server error: ${response.statusCode}, Body: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Exception in sending transaction: $e");
    return false;
  }
}

Future<void> makeINTransaction({
  required String productID,
  required String type,
  required double quantity,
  required String userID,
  required String unitID,
  required String department,
  required String supplier,
  required BuildContext context,
}) async {
  final prefs = await SharedPreferences.getInstance();
  var connectivityResult = await Connectivity().checkConnectivity();
  bool isConnected = connectivityResult != ConnectivityResult.none;

  Map<String, dynamic> transactionData = {
    "productID": productID,
    "type": type,
    "quantity": quantity,
    "userID": userID,
    "unitID": unitID,
    "department": department,
    "supplier": supplier,
  };

  if (!isConnected) {
    List<String> offlineList = prefs.getStringList(offlineKey) ?? [];
    offlineList.add(jsonEncode(transactionData));
    await prefs.setStringList(offlineKey, offlineList);

    showfalseSnackBar(
      context: context,
      message: "لا يوجد اتصال بالإنترنت، تم حفظ العملية مؤقتًا",
      icon: Icons.wifi_off,
    );

    if (Navigator.canPop(context)) Navigator.pop(context);
    return;
  }

  bool success = await sendTransaction(
    productID: productID,
    type: type,
    quantity: quantity,
    userID: userID,
    unitID: unitID,
    department: department,
    supplier: supplier,
  );

  if (success) {
    showTrueSnackBar(
      context: context,
      message: "تمت العملية بنجاح",
      icon: Icons.check_circle,
    );
    Navigator.of(context).pop();
  } else {
    showfalseSnackBar(
      context: context,
      message: "فشلت العملية",
      icon: Icons.report_problem,
    );
  }
}

Future<void> sendOfflineTransactionss(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> offlineList = prefs.getStringList(offlineKey) ?? [];

  if (offlineList.isEmpty) return;

  List<String> failedTransactions = [];

  for (String jsonString in offlineList) {
    Map<String, dynamic> transactionData = jsonDecode(jsonString);

    bool success = await sendTransaction(
      productID: transactionData["productID"],
      type: transactionData["type"],
      quantity: transactionData["quantity"],
      userID: transactionData["userID"],
      unitID: transactionData["unitID"],
      department: transactionData["department"],
      supplier: transactionData["supplier"],
    );

    if (!success) {
      failedTransactions.add(jsonString);
    }
  }

  await prefs.setStringList(offlineKey, failedTransactions);

  if (failedTransactions.isEmpty) {
    showTrueSnackBar(
      context: context,
      message: "تم إرسال كل المعاملات المؤقتة بنجاح",
      icon: Icons.check_circle,
    );
  } else {
 
  }
}
