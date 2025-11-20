
/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


// --- Add Product API call ---
Future<String?> addNewProduct({
  required String name,
  required String bracode,
  required int availableQuantity,
  required String unit,
  required String supplierAcceptedID,
}) async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.product.add);

  final productData = {
    "name": name,
    "bracode": bracode,
    "availableQuantity": availableQuantity,
    "unit": unit,
    "supplierAccepted": supplierAcceptedID,
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
      return null;
    }
  } catch (e) {
    print('Exception while adding product: $e');
    return null;
  }
}

// --- Add Transaction API call ---
Future<bool> addTransaction({
  required String productID,
  required int quantity,
  required String userID,
  required String unitID,
  required String departmentID,
  required String supplier,
}) async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.transaction.add);

  final body = {
    "productID": productID,
    "type": "IN",
    "quantity": quantity,
    "userID": userID,
    "unit": unitID,
    "department": departmentID,
    "supplier": supplier,
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print('Exception while adding transaction: $e');
    return false;
  }
}

// --- Main function: handle adding product + transaction with offline support ---
Future<void> makeINTransactionwhenAddOfflineSafe({
  required String? productID,
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
  final prefs = await SharedPreferences.getInstance();
  var connectivityResult = await Connectivity().checkConnectivity();
  bool isConnected = connectivityResult != ConnectivityResult.none;

  Map<String, dynamic> transactionData = {
    "productID": productID,
    "name": name,
    "bracode": bracode,
    "quantity": quantity,
    "userID": userID,
    "unitID": unitID,
    "departmentID": departmentID,
    "supplier": supplier,
    "supplierID": supplierID,
  };

  if (!isConnected) {
    List<String> offlineList = prefs.getStringList('offline_transactionss') ?? [];
    offlineList.add(jsonEncode(transactionData));
    await prefs.setStringList('offline_transactionss', offlineList);

    showfalseSnackBar(
      context: context,
      message: 'لا يوجد اتصال بالإنترنت، تم حفظ العملية مؤقتًا',
      icon: Icons.wifi_off,
    );
    Navigator.pop(context);
    return;
  }

  String? finalProductID = productID;

  if (finalProductID == null || finalProductID.isEmpty) {
    finalProductID = await addNewProduct(
      name: name,
      bracode: bracode,
      availableQuantity: quantity,
      unit: unitID,
      supplierAcceptedID: supplierID,
    );

    if (finalProductID == null) {
      showfalseSnackBar(
        context: context,
        message: "فشل إضافة المنتج، حاول مرة أخرى",
        icon: Icons.error,
      );
      return;
    }
  }

  bool success = await addTransaction(
    productID: finalProductID,
    quantity: quantity ,
    userID: userID,
    unitID: unitID,
    departmentID: departmentID,
    supplier: supplier,
  );

  if (success) {
    showTrueSnackBar(
      context: context,
      message: "تمت العملية بنجاح",
      icon: Icons.check_circle,
    );
  } else {
    showfalseSnackBar(
      context: context,
      message: "فشل إضافة المعاملة",
      icon: Icons.error,
    );
  }
}

// --- إرسال المعاملات المعلقة عند عودة الإنترنت ---
Future<void> sendOfflineTransactions(  BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> offlineList = prefs.getStringList('offline_transactionss') ?? [];

  if (offlineList.isEmpty) return;

  List<String> failedTransactions = [];

  for (String jsonString in offlineList) {
    Map<String, dynamic> transactionData = jsonDecode(jsonString);

    String? productID = transactionData["productID"];

    // إذا كان معرف المنتج موجود بالفعل، نرسله مباشرة
    var depId;
    var useridd;
  await  Localls.getdepartment().then((v)=>depId=v);
  await  Localls.getUserID().then((v)=>useridd=v);
    if (productID != null && productID.toString().isNotEmpty) {
      bool success = await addTransaction(
        productID: productID,
        quantity: transactionData["quantity"],
        userID: useridd.toString(),
        unitID: transactionData["unitID"],
        departmentID:depId.toString(),
        supplier: transactionData["supplier"],
      );

      if (!success) {
        failedTransactions.add(jsonString);
      }
      continue;
    }

    // إذا لم يكن هناك معرف، ننشئ المنتج أولاً
    String? newProductID = await addNewProduct(
      name: transactionData["name"] ?? "",
      bracode: transactionData["bracode"] ?? "",
      availableQuantity: transactionData["quantity"] ?? 0,
      unit: transactionData["unitID"] ?? "",
      supplierAcceptedID: transactionData["supplierID"] ?? "",
    );

    if (newProductID == null) {
      failedTransactions.add(jsonString);
      continue;
    }

    bool success = await addTransaction(
      productID: newProductID,
      quantity: transactionData["quantity"] ,
      userID: transactionData["userID"],
      unitID: transactionData["unitID"],
      departmentID: transactionData["departmentID"],
      supplier: transactionData["supplier"],
    );

    if (!success) {
      failedTransactions.add(jsonString);
    }
  }

  await prefs.setStringList('offline_transactionss', failedTransactions);

  if (failedTransactions.isEmpty) {
    showTrueSnackBar(
      context: context,
      message: 'تم إرسال كل المعاملات المعلقة بنجاح',
      icon: Icons.check_circle,
    );
  } else {
    showfalseSnackBar(
      context: context,
      message: 'بعض المعاملات لم ترسل، سيتم المحاولة لاحقاً',
      icon: Icons.error,
    );
  }
}

*/
///qty

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:saladafactory/core/Widgets/showsnackbar.dart';
// import 'package:saladafactory/core/utils/apiEndpoints.dart';
// import 'package:saladafactory/core/utils/localls.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

// // --- Add Product ---
// Future<String?> addNewProduct({
//   required String name,
//   required String bracode,
//   required int availableQuantity,
//   required String unit,
//   required String supplierAcceptedID,
// }) async {
//   final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.product.add);

//   final productData = {
//     "name": name,
//     "bracode": bracode,
//     "availableQuantity": availableQuantity,
//     "unit": unit,
//     "supplierAccepted": supplierAcceptedID,
//   };

//   try {
//     final response = await http.post(
//       url,
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode(productData),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final data = json.decode(response.body);
//       return data["data"]["_id"];
//     } else {
//       print('Failed to add product: ${response.statusCode}');
//       return null;
//     }
//   } catch (e) {
//     print('Exception while adding product: $e');
//     return null;
//   }
// }

// // --- تحديث الكمية محلياً ---
// Future<void> updateLocalProductQuantity(String productID, int quantity, String type) async {
//   final prefs = await SharedPreferences.getInstance();
//   String? productQuantitiesJson = prefs.getString('local_product_quantities');

//   Map<String, dynamic> quantities = {};
//   if (productQuantitiesJson != null) {
//     quantities = jsonDecode(productQuantitiesJson);
//   }

//   int currentQty = (quantities[productID]?.toInt()) ?? 0;
//   int newQty;

//   if (type == "OUT") {
//     newQty = (quantity > currentQty) ? 0 : currentQty - quantity;
//   } else {
//     newQty = currentQty + quantity;
//   }

//   quantities[productID] = newQty;
//   await prefs.setString('local_product_quantities', jsonEncode(quantities));
//   print("✅ الكمية المحلية [$productID]: $newQty");
// }

// Future<void> updateProductQuantityLocally(String productID, int quantity, String type) async {
//   final prefs = await SharedPreferences.getInstance();
//   final cachedData = prefs.getString('cached_Products');

//   if (cachedData == null) {
//     print("❌ لا توجد بيانات منتجات مخزنة محلياً في cached_Products");
//     return;
//   }

//   List<dynamic> products = json.decode(cachedData);
//   bool updated = false;

//   for (int i = 0; i < products.length; i++) {
//     final product = products[i];
//     if (product['_id'].toString() == productID.toString()) {
//       int currentQty = product['availableQuantity'] ?? 0;

//       int newQty;
//       if (type == "OUT") {
//         newQty = (quantity > currentQty) ? 0 : currentQty - quantity;
//       } else {
//         newQty = currentQty + quantity;
//       }

//       products[i]['availableQuantity'] = newQty;
//       updated = true;
//       print("✅ الكمية الجديدة للمنتج $productID: $newQty");
//       break;
//     }
//   }

//   if (updated) {
//     await prefs.setString('cached_Products', json.encode(products));
//     print("✅ تم حفظ الكمية الجديدة في SharedPreferences.");
//   } else {
//     print("❌ لم يتم العثور على المنتج $productID في الكاش.");
//   }
// }

// // --- Add Transaction ---
// Future<bool> addTransaction({
//   required String productID,
//   required int quantity,
//   required String userID,
//   required String unitID,
//   required String departmentID,
//   required String supplier,
//   String type = "IN",
// }) async {
//   final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.transaction.add);

//   final body = {
//     "productID": productID,
//     "type": type,
//     "quantity": quantity,
//     "userID": userID,
//     "unit": unitID,
//     "department": departmentID,
//     "supplier": supplier,
//   };

//   try {
//     final response = await http.post(
//       url,
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode(body),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       await updateProductQuantityLocally(productID, quantity, type);
//       await updateLocalProductQuantity(productID, quantity, type);
//       return true;
//     } else {
//       print('Failed to add transaction: ${response.statusCode}');
//       return false;
//     }
//   } catch (e) {
//     print('Exception while adding transaction: $e');
//     return false;
//   }
// }

// // --- Main Transaction Function with Offline Support ---
// Future<void> makeINTransactionwhenAddOfflineSafe({
//   required String? productID,
//   required String name,
//   required String bracode,
//   required int quantity,
//   required String userID,
//   required String unitID,
//   required String departmentID,
//   required String supplier,
//   required String supplierID,
//   required BuildContext context,
//   String type = "IN",
// }) async {
//   final prefs = await SharedPreferences.getInstance();
//   var connectivityResult = await Connectivity().checkConnectivity();
//   bool isConnected = connectivityResult != ConnectivityResult.none;

//   Map<String, dynamic> transactionData = {
//     "productID": productID,
//     "name": name,
//     "bracode": bracode,
//     "quantity": quantity,
//     "userID": userID,
//     "unitID": unitID,
//     "departmentID": departmentID,
//     "supplier": supplier,
//     "supplierID": supplierID,
//     "type": type,
//   };

//   if (!isConnected) {
//     List<String> offlineList = prefs.getStringList('offline_transactionss') ?? [];
//     offlineList.add(jsonEncode(transactionData));
//     await prefs.setStringList('offline_transactionss', offlineList);
    
//     if (productID != null) {
//       await updateLocalProductQuantity(productID, quantity, type);
//       await updateProductQuantityLocally(productID, quantity, type);
//     }

//     showfalseSnackBar(
//       context: context,
//       message: 'لا يوجد اتصال بالإنترنت، تم حفظ العملية مؤقتًا',
//       icon: Icons.wifi_off,
//     );
//     Navigator.pop(context);
//     return;
//   }

//   String? finalProductID = productID;

//   if (finalProductID == null || finalProductID.isEmpty) {
//     finalProductID = await addNewProduct(
//       name: name,
//       bracode: bracode,
//       availableQuantity: quantity,
//       unit: unitID,
//       supplierAcceptedID: supplierID,
//     );

//     if (finalProductID == null) {
//       showfalseSnackBar(
//         context: context,
//         message: "فشل إضافة المنتج، حاول مرة أخرى",
//         icon: Icons.error,
//       );
//       return;
//     }
//   }

//   bool success = await addTransaction(
//     productID: finalProductID,
//     quantity: quantity,
//     userID: userID,
//     unitID: unitID,
//     departmentID: departmentID,
//     supplier: supplier,
//     type: type,
//   );

//   if (success) {
//     showTrueSnackBar(
//       context: context,
//       message: "تمت العملية بنجاح",
//       icon: Icons.check_circle,
//     );
//   } else {
//     showfalseSnackBar(
//       context: context,
//       message: "فشل إضافة المعاملة",
//       icon: Icons.error,
//     );
//   }
// }

// // --- إرسال المعاملات المعلقة عند عودة الإنترنت ---
// Future<void> sendOfflineTransactions(BuildContext context) async {
//   final prefs = await SharedPreferences.getInstance();
//   List<String> offlineList = prefs.getStringList('offline_transactionss') ?? [];

//   if (offlineList.isEmpty) return;

//   List<String> failedTransactions = [];

//   for (String jsonString in offlineList) {
//     Map<String, dynamic> transactionData = jsonDecode(jsonString);

//     String? productID = transactionData["productID"];
//     var depId, useridd;
//     await Localls.getdepartment().then((v) => depId = v);
//     await Localls.getUserID().then((v) => useridd = v);

//     if (productID != null && productID.toString().isNotEmpty) {
//       bool success = await addTransaction(
//         productID: productID,
//         quantity: transactionData["quantity"],
//         userID: useridd.toString(),
//         unitID: transactionData["unitID"],
//         departmentID: depId.toString(),
//         supplier: transactionData["supplier"],
//         type: transactionData["type"] ?? "IN",
//       );

//       if (!success) failedTransactions.add(jsonString);
//       continue;
//     }

//     String? newProductID = await addNewProduct(
//       name: transactionData["name"] ?? "",
//       bracode: transactionData["bracode"] ?? "",
//       availableQuantity: transactionData["quantity"] ?? 0,
//       unit: transactionData["unitID"] ?? "",
//       supplierAcceptedID: transactionData["supplierID"] ?? "",
//     );

//     if (newProductID == null) {
//       failedTransactions.add(jsonString);
//       continue;
//     }

//     bool success = await addTransaction(
//       productID: newProductID,
//       quantity: transactionData["quantity"],
//       userID: transactionData["userID"],
//       unitID: transactionData["unitID"],
//       departmentID: transactionData["departmentID"],
//       supplier: transactionData["supplier"],
//       type: transactionData["type"] ?? "IN",
//     );

//     if (!success) failedTransactions.add(jsonString);
//   }

//   await prefs.setStringList('offline_transactionss', failedTransactions);

//   if (failedTransactions.isEmpty) {
//     showTrueSnackBar(
//       context: context,
//       message: 'تم إرسال كل المعاملات المعلقة بنجاح',
//       icon: Icons.check_circle,
//     );
//   } else {
//     showfalseSnackBar(
//       context: context,
//       message: 'بعض المعاملات لم ترسل، سيتم المحاولة لاحقاً',
//       icon: Icons.error,
//     );
//   }
// }

// Future<Map<String, dynamic>?> getProductCached(BuildContext context, String productID, {int? newQuantity}) async {
//   final prefs = await SharedPreferences.getInstance();
//   final cachedData = prefs.getString('cached_Products');

//   if (cachedData == null) {
//     print("❌ لا توجد بيانات منتجات مخزنة محلياً");
//     return null;
//   }

//   List<dynamic> products = json.decode(cachedData);
  
//   for (var product in products) {
//     if (product['_id'].toString() == productID.toString()) {
//       if (newQuantity != null) {
//         product['availableQuantity'] = newQuantity;
//         await prefs.setString('cached_Products', json.encode(products));
//         print("✅ تم تحديث الكمية للمنتج $productID إلى $newQuantity");
//       }
//       return Map<String, dynamic>.from(product);
//     }
//   }

//   print("❌ المنتج $productID غير موجود في الكاش");
//   return null;
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// --- أدوات التعامل مع قائمة String ---
Future<void> cacheStringList(List<String> items) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('offline_transactionss', items);
  print("✅ تم تخزين قائمة السلاسل النصية.");
}

Future<List<String>> getCachedStringList() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('offline_transactionss') ?? [];
}

Future<void> removeItemFromCachedList(String itemToRemove) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> items = prefs.getStringList('offline_transactionss') ?? [];
  items.remove(itemToRemove);
  await prefs.setStringList('offline_transactionss', items);
  print("🗑️ تم حذف العنصر: $itemToRemove");
}

// --- إضافة منتج جديد ---
Future<String?> addNewProduct({
  required String name,
  required String bracode,
  required double availableQuantity,
  required String unit,
  required String supplierAcceptedID,
}) async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.product.add);

  final productData = {
    "name": name,
    "bracode": bracode,
    "availableQuantity": availableQuantity,
    "unit": unit,
    "supplierAccepted": supplierAcceptedID,
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
      print('❌ Failed to add product: ${response.statusCode}');
      print('❌ Failed to add product: ${response.body}');
      return null;
    }
  } catch (e) {
    print('❌ Exception while adding product: $e');
    return null;
  }
}

// --- تحديث الكمية محلياً ---
Future<void> updateLocalProductQuantity(String productID, double quantity, String type) async {
  final prefs = await SharedPreferences.getInstance();
  String? productQuantitiesJson = prefs.getString('local_product_quantities');

  Map<String, dynamic> quantities = {};
  if (productQuantitiesJson != null) {
    quantities = jsonDecode(productQuantitiesJson);
  }

  double currentQty = (quantities[productID]?.toDouble()) ?? 0;
  double newQty = (type == "OUT")
      ? (quantity > currentQty ? 0 : currentQty - quantity)
      : currentQty + quantity;

  quantities[productID] = newQty;
  await prefs.setString('local_product_quantities', jsonEncode(quantities));
  print("✅ الكمية المحلية [$productID]: $newQty");
}

Future<void> updateProductQuantityLocally(String productID, double quantity, String type) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedData = prefs.getString('cached_Products');

  if (cachedData == null) return;

  List<dynamic> products = json.decode(cachedData);
  bool updated = false;

  for (int i = 0; i < products.length; i++) {
    final product = products[i];
    if (product['_id'].toString() == productID.toString()) {
      double currentQty = product['availableQuantity'] ?? 0;

      double newQty = (type == "OUT")
          ? (quantity > currentQty ? 0 : currentQty - quantity)
          : currentQty + quantity;

      products[i]['availableQuantity'] = newQty;
      updated = true;
      break;
    }
  }

  if (updated) {
    await prefs.setString('cached_Products', json.encode(products));
  }
}

// --- إرسال معاملة ---
Future<bool> addTransaction({
  required String productID,
  required double quantity,
  required String userID,
  required String unitID,
  required String departmentID,
  required String supplier,
  String type = "IN",
}) async {
  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.transaction.add);

  final body = {
    "productID": productID,
    "type": type,
    "quantity": quantity,
    "userID": userID,
    "unit": unitID,
    "department": departmentID,
    "supplier": supplier,
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      await updateProductQuantityLocally(productID, quantity, type);
      await updateLocalProductQuantity(productID, quantity, type);
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

// --- العملية الرئيسية عند عدم الاتصال بالإنترنت ---
Future<void> makeINTransactionwhenAddOfflineSafe({
  required String? productID,
  required String name,
  required String bracode,
  required double quantity,
  required String userID,
  required String unitID,
  required String departmentID,
  required String supplier,
  required String supplierID,
  required BuildContext context,
  String type = "IN",
}) async {
  final prefs = await SharedPreferences.getInstance();
  var connectivityResult = await Connectivity().checkConnectivity();
  bool isConnected = connectivityResult != ConnectivityResult.none;

  Map<String, dynamic> transactionData = {
    "productID": productID,
    "name": name,
    "bracode": bracode,
    "quantity": quantity,
    "userID": userID,
    "unitID": unitID,
    "departmentID": departmentID,
    "supplier": supplier,
    "supplierID": supplierID,
    "type": type,
  };

  if (!isConnected) {
    List<String> offlineList = prefs.getStringList('offline_transactionss') ?? [];
    offlineList.add(jsonEncode(transactionData));
    await prefs.setStringList('offline_transactionss', offlineList);

    List<String> ids = await getCachedStringList();
    if (productID != null) {
      ids.add(productID);
      await cacheStringList(ids);
    }

    await updateLocalProductQuantity(productID ?? "", quantity, type);
    await updateProductQuantityLocally(productID ?? "", quantity, type);

    showfalseSnackBar(
      context: context,
      message: 'لا يوجد اتصال بالإنترنت، تم حفظ العملية مؤقتًا',
      icon: Icons.wifi_off,
    );
    Navigator.pop(context);
    return;
  }

  String? finalProductID = productID;

  if (finalProductID == null || finalProductID.isEmpty) {
    finalProductID = await addNewProduct(
      name: name,
      bracode: bracode,
      availableQuantity: quantity,
      unit: unitID,
      supplierAcceptedID: supplierID,
    );

    if (finalProductID == null) {
      showfalseSnackBar(
        context: context,
        message: "فشل إضافة المنتج، حاول مرة أخرى",
        icon: Icons.error,
      );
      return;
    }
  }

  bool success = await addTransaction(
    productID: finalProductID,
    quantity: quantity,
    userID: userID,
    unitID: unitID,
    departmentID: departmentID,
    supplier: supplier,
    type: type,
  );

  if (success) {
    showTrueSnackBar(
      context: context,
      message: "تمت العملية بنجاح",
      icon: Icons.check_circle,
    );
  } else {
    showfalseSnackBar(
      context: context,
      message: "فشل إضافة المعاملة",
      icon: Icons.error,
    );
  }
}

// --- إرسال المعاملات المؤقتة بعد الاتصال ---
Future<void> sendOfflineTransactions(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> offlineList = prefs.getStringList('offline_transactionss') ?? [];

  if (offlineList.isEmpty) return;

  List<String> remainingTransactions = [];

  for (String jsonString in offlineList) {
    try {
      Map<String, dynamic> transactionData = jsonDecode(jsonString);
      String? productID = transactionData["productID"];

      var depId, useridd;
      await Localls.getdepartment().then((v) => depId = v);
      await Localls.getUserID().then((v) => useridd = v);

      String finalProductID = productID ?? "";

      if (finalProductID.isEmpty) {
        finalProductID = await addNewProduct(
          name: transactionData["name"] ?? "",
          bracode: transactionData["bracode"] ?? "",
          availableQuantity: transactionData["quantity"] ?? 0,
          unit: transactionData["unitID"] ?? "",
          supplierAcceptedID: transactionData["supplierID"] ?? "",
        ) ?? "";

        if (finalProductID.isEmpty) {
          remainingTransactions.add(jsonString);
          continue;
        }
      }

      bool success = await addTransaction(
        productID: finalProductID,
        quantity: transactionData["quantity"],
        userID: useridd.toString(),
        unitID: transactionData["unitID"],
        departmentID: depId.toString(),
        supplier: transactionData["supplier"],
        type: transactionData["type"] ?? "IN",
      );

      if (!success) {
        remainingTransactions.add(jsonString);
      }
    } catch (e) {
      remainingTransactions.add(jsonString);
    }
  }

  await prefs.setStringList('offline_transactionss', remainingTransactions);

  if (remainingTransactions.isEmpty) {
    showTrueSnackBar(
      context: context,
      message: 'تم إرسال كل المعاملات المعلقة بنجاح',
      icon: Icons.check_circle,
    );
  } else {
    // showfalseSnackBar(
    //   context: context,
    //   message: 'بعض المعاملات لم ترسل، سيتم المحاولة لاحقاً',
    //   icon: Icons.error,
    // );
  }
}
