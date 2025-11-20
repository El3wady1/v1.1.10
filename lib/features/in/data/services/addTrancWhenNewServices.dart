/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/app_router.dart';
import 'package:saladafactory/features/in/data/services/AddnewProductServices.dart';

import '../../../../core/utils/apiEndpoints.dart';

Future makeINTransactionwhenNoproductAdd({
  required String productID,
  required String name,
  required String bracode,
  required int quantity,
  required String userID,
  required String unitID,
  required String departmentID,
  required String supplier,
  required String supplierID,
  required BuildContext context,
}) async {
  var newProductID;
  print("kj" + name);
  await AddnewProduct(
    name: name,
    bracode: bracode,
    availableQuantity: quantity,
    unit: unitID,
    supplierAcceptedID: supplierID,
  ).then((x) => newProductID = x);
  print(newProductID ?? null);
  if (newProductID != null) {
    final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.transaction.addwhenaddnoProduct);

    final Map<String, dynamic> body = {
      "productID": newProductID,
      "type": "IN",
      "quantity": quantity,
      "userID": userID,
      "unit": unitID,
      "department": departmentID,
      "supplier": supplier,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        showTrueSnackBar(
          context: context,
          message: "تمت العملية بنجاح",
          icon: Icons.check_circle,
        );

        print("Response: ${response.body}");
      } else if (response.body.contains("available quantity is only")) {
        showfalseSnackBar(
          context: context,
          message: "الكمية الموجودة ليست كافية",
          icon: Icons.dangerous,
        );
      } else {
        showfalseSnackBar(
          context: context,
          message: "فشلت العملية",
          icon: Icons.report_problem,
        );

        print("😬 Server error: ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      showfalseSnackBar(
        context: context,
        message: "هناك مشكله، أعد المحاولة لاحقًا",
        icon: Icons.error,
      );

      print("❌ Exception: $e");
    }
  } else {
    showfalseSnackBar(
        context: context, message: "اعد مسح الباركود", icon: Icons.qr_code);
  }
}
*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';

// ✅ إضافة منتج
Future<String?> addNewProductOfflineSafe({
  required String name,
  required String bracode,
  required double availableQuantity,
  required String unit,
  required String supplierAcceptedID,
  required String mainProduct,
  required String packSize,
  required String expireDate,
  required String price,
}) async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.product.add);

  final productData = {
     "name": name,
    "bracode": bracode,
    "availableQuantity": availableQuantity,
    "unit": unit,
    "supplierAccepted": supplierAcceptedID,
    "mainProduct": mainProduct,
    "packSize": packSize,
    "expireDate": expireDate,
    "price": price
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(productData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data["data"]["_id"];
    } else {
      print('Failed to add product: ${response.statusCode}');
      print('Failed to add product: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error adding product: $e');
    return null;
  }
}

// ✅ إضافة معاملة
Future<bool> addTransactionOfflineSafe({
  required String productID,
  required double quantity,
  required String userID,
  required String unitID,
  required String departmentID,
  required String supplier,
  required String packSize,
  required String price,
  required String expireDate,
  required String mainProduct,
}) async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.transaction.addwhenaddnoProduct);

  final body = {
    "productID": productID,
    "type": "IN",
    "quantity": quantity,
    "userID": userID,
    "unit": unitID,
    "department": departmentID,
    "supplier": supplier,
    "mainProduct": mainProduct,
    "packSize": packSize,
    "expireDate": expireDate,
    "price": price
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print('Error adding transaction: $e');
    return false;
  }
}

// ✅ العملية الموحدة الرئيسية
Future<void> makeINTransactionwhenNoproductAdd({
  required String name,
  required String bracode,
  required double quantity,
  required String userID,
  required String unitID,
  required String departmentID,
  required String supplier,
  required String supplierID,
  required BuildContext context,
  required String productID,
  required String packSize,
  required String price,
  required String expireDate,
  required String mainProduct,
}) async {
  final prefs = await SharedPreferences.getInstance();
  var connectivityResult = await Connectivity().checkConnectivity();
  bool isConnected = connectivityResult != ConnectivityResult.none;

  Map<String, dynamic> transactionData = {
    "name": name,
    "bracode": bracode,
    "quantity": quantity,
    "userID": userID,
    "unitID": unitID,
    "departmentID": departmentID,
    "supplier": supplier,
    "supplierID": supplierID,
    "mainProduct": mainProduct,
    "packSize": packSize,
    "expireDate": expireDate,
    "price": price
  };

  if (!isConnected) {
    List<String> offlineList = prefs.getStringList('offline_in_transactions') ?? [];
    offlineList.add(jsonEncode(transactionData));
    await prefs.setStringList('offline_in_transactions', offlineList);
    await prefs.setStringList('cached_Products', offlineList);

    showfalseSnackBar(
      context: context,
      message: 'لا يوجد اتصال بالإنترنت، تم حفظ العملية محليًا',
      icon: Icons.wifi_off,
    );
    return;
  }

  String? newProductID = await addNewProductOfflineSafe(
    name: name,
    bracode: bracode,
    availableQuantity: quantity,
    unit: unitID,
    supplierAcceptedID: supplierID,
    mainProduct: mainProduct,
    packSize: packSize,
    expireDate: expireDate,
    price: price,
  );

  if (newProductID == null) {
    showfalseSnackBar(
      context: context,
      message: "فشل إضافة المنتج، حاول مرة أخرى",
      icon: Icons.error,
    );
    return;
  }

  bool transactionAdded = await addTransactionOfflineSafe(
    productID: newProductID,
    quantity: quantity,
    userID: userID,
    unitID: unitID,
    departmentID: departmentID,
    supplier: supplier,
    mainProduct: mainProduct,
    packSize: packSize,
    expireDate: expireDate,
    price: price,
  );

  if (transactionAdded) {
    showTrueSnackBar(
      context: context,
      message: "تمت العملية بنجاح",
      icon: Icons.check_circle,
    );

    await sendSavedTransactions(context);
  } else {
    // showfalseSnackBar(
    //   context: context,
    //   message: "فشل إضافة المعاملة",
    //   icon: Icons.error,
    // );
  }
}

// ✅ دالة لإرسال العمليات المحفوظة عند الاتصال
Future<void> sendSavedTransactions(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> offlineList = prefs.getStringList('offline_in_transactions') ?? [];

  if (offlineList.isEmpty) return;

  List<String> failedTransactions = [];

  for (String jsonString in offlineList) {
    Map<String, dynamic> data = jsonDecode(jsonString);

    String? productID = await addNewProductOfflineSafe(
      name: data["name"],
      bracode: data["bracode"],
      availableQuantity: data["quantity"],
      unit: data["unitID"],
      supplierAcceptedID: data["supplierID"],
      mainProduct: data["mainProduct"],
      packSize: data["packSize"],
      expireDate: data["expireDate"],
      price: data["price"],
    );

    if (productID == null) {
      failedTransactions.add(jsonString);
      continue;
    }

    bool added = await addTransactionOfflineSafe(
      productID: productID,
      quantity: data["quantity"],
      userID: data["userID"],
      unitID: data["unitID"],
      departmentID: data["departmentID"],
      supplier: data["supplier"],
      mainProduct: data["mainProduct"],
      packSize: data["packSize"],
      expireDate: data["expireDate"],
      price: data["price"],
    );

    if (!added) {
      failedTransactions.add(jsonString);
    }
  }

  await prefs.setStringList('offline_in_transactions', failedTransactions);

  if (failedTransactions.isEmpty) {
    showTrueSnackBar(
      context: context,
      message: 'تمت مزامنة جميع العمليات المحفوظة',
      icon: Icons.cloud_done,
    );
  } else {
    showfalseSnackBar(
      context: context,
      message: 'فشلت مزامنة بعض العمليات، سيتم المحاولة لاحقًا',
      icon: Icons.sync_problem,
    );
  }
}
