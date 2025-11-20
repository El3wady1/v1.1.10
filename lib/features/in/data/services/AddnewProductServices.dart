import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/apiEndpoints.dart';
/*
Future AddnewProduct({
  required String name,
  required String bracode,
  required int availableQuantity,
  required String unit,
  required String supplierAcceptedID,
}) async {
  final url = Uri.parse(Apiendpoints.baseUrl+Apiendpoints.product.add);

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
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(productData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
       final data = json.decode(response.body);
       print(data["data"]["_id"]);
      return data["data"]["_id"];
      print('✅ تم إرسال المنتج بنجاح!');
    } else {
      print('❌ فشل في الإرسال. الكود: ${response.statusCode}');
      print('❌ فشل ف اضافه منتج: ${response.statusCode}');
      print('📄 الرسالة: ${response.body}');
    }
  } catch (e) {
    print('⚠️ حصل خطأ أثناء الإرسال: $e');
  }
}
*/
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// اسم المفتاح اللي هنخزن فيه قائمة المنتجات المؤقتة
const String offlineProductsKey = 'offline_products';

Future<bool> isConnected() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

// حفظ المنتج مؤقتًا في Shared Preferences
Future<void> saveProductOffline(Map<String, dynamic> productData) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> offlineProducts = prefs.getStringList(offlineProductsKey) ?? [];

  // حول المنتج إلى JSON string وأضفه للقائمة
  offlineProducts.add(jsonEncode(productData));

  await prefs.setStringList(offlineProductsKey, offlineProducts);
  print('🔄 تم حفظ المنتج محلياً في Shared Preferences');
}

// إرسال المنتجات المؤقتة عند توفر الانترنت
Future<void> sendPendingProducts() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> offlineProducts = prefs.getStringList(offlineProductsKey) ?? [];

  if (offlineProducts.isEmpty) {
    print('لا توجد منتجات معلقة للإرسال.');
    return;
  }

  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.product.add);

  for (var productJson in List<String>.from(offlineProducts)) {
    Map<String, dynamic> productData = jsonDecode(productJson);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ تم إرسال المنتج المعلق بنجاح!');
        // حذف المنتج من القائمة بعد إرساله بنجاح
        offlineProducts.remove(productJson);
        await prefs.setStringList(offlineProductsKey, offlineProducts);
      } else {
        print('❌ فشل إرسال المنتج المعلق. كود: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ خطأ أثناء إرسال المنتج المعلق: $e');
      break; // توقف عند أول خطأ
    }
  }
}

// دالة إضافة منتج مع دعم الـ offline
Future<String?> AddnewProduct({
  required String name,
  required String bracode,
  required double availableQuantity,
  required String unit,
  required String supplierAcceptedID,
}) async {
  final productData = {
    "name": name,
    "bracode": bracode,
    "availableQuantity": availableQuantity,
    "unit": unit,
    "supplierAccepted": supplierAcceptedID,
  };

  if (!await isConnected()) {
    await saveProductOffline(productData);
    print('🔄 لا يوجد اتصال. تم حفظ المنتج محليًا.');
    return null;
  }

  final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.product.add);

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(productData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      print('✅ تم إرسال المنتج بنجاح!');
      return data["data"]["_id"];
    } else {
      print('❌ فشل في الإرسال. كود: ${response.statusCode}');
      print('❌ رسالة الخطأ: ${response.body}');
      return null;
    }
  } catch (e) {
    print('⚠️ حصل خطأ أثناء الإرسال: $e');
    return null;
  }
}
