import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/app_router.dart';
import 'package:saladafactory/core/utils/Strings.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/core/utils/cacheHelper.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:saladafactory/features/home/presentation/view/homeView.dart';
import 'package:saladafactory/features/login/data/services/getDevicesID.dart';
import 'package:saladafactory/features/login/data/services/getDevicesName.dart';

class LoginService {
  // تعريف الألوان الثابتة
  static const Color primaryColor = Color(0xFF74826A);      // الأخضر الأساسي
  static const Color accentColor = Color(0xFFEDBE2C);       // الذهبي
  static const Color secondaryColor = Color(0xFFCDBCA2);    // البيج
  static const Color backgroundColor = Color(0xFFF3F4EF);   // الأبيض الكريمي

  static Future<void> login({
    required String password,
    required BuildContext context,
  }) async {
    bool shouldShowLoading = true;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (shouldShowLoading && context.mounted) {
        _showLoadingDialog(context);
      }
    });

    try {
      // جلب معلومات الجهاز بشكل متوازي
      final deviceId = await getDeviceId();
      final deviceName = await getDeviceName();

      final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.auth.login);
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        "password": password,
        "Appversion": Strings.appVersion,
        "deviceId": deviceId.toString(),
        "deviceName": deviceName.toString(),
      });

      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(minutes: 10));

      // إغلاق loading
      shouldShowLoading = false;
      if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await _handleLoginResponse(response, context);

    } on http.ClientException {
      shouldShowLoading = false;
      _closeLoadingDialog(context);
      _showErrorAlert(
        context,
        title: "انقطاع الاتصال".tr(),
        message: "تفقد اتصالك بالإنترنت وحاول مرة أخرى".tr(),
        icon: Icons.wifi_off,
      );
    } on TimeoutException {
      shouldShowLoading = false;
      _closeLoadingDialog(context);
      _showErrorAlert(
        context,
        title: "انتهت المهلة".tr(),
        message: "استغرقت العملية وقتاً طويلاً، حاول مرة أخرى".tr(),
        icon: Icons.timer_off,
      );
    } catch (e) {
      shouldShowLoading = false;
      _closeLoadingDialog(context);
      print('LoginService Unexpected Error: ${e.toString()}');
      _showErrorAlert(
        context,
        title: "خطأ غير متوقع".tr(),
        message: "حدث خطأ غير متوقع، حاول مرة أخرى".tr(),
        icon: Icons.error_outline,
      );
    }
  }

  static void _closeLoadingDialog(BuildContext context) {
    if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static Future<void> _handleLoginResponse(
      http.Response response, BuildContext context) async {
    final statusCode = response.statusCode;
    
    if (statusCode == 200 || statusCode == 201) {
      await _handleSuccessResponse(response, context);
    } else {
      _handleErrorResponse(response, context);
    }
  }

  static Future<void> _handleSuccessResponse(
      http.Response response, BuildContext context) async {
    try {
      final responseData = jsonDecode(response.body);
      final token = responseData["token"];
      
      if (token != null && responseData["data"] != null) {
        await _saveUserData(responseData);
        
        if (context.mounted) {
          Routting.pushreplaced(context,  Homeview());
          showTrueSnackBar(context: context, message:"تم تسجيل الدخول بنجاح".tr() , icon: Icons.check_circle_rounded);
        }
      } else {
        throw Exception("Invalid response format");
      }
    } catch (e) {
      print('Success Response Parsing Error: $e');
      _showErrorAlert(
        context,
        title: "خطأ في البيانات".tr(),
        message: "حدث خطأ في معالجة البيانات".tr(),
        icon: Icons.data_array,
      );
    }
  }

  static Future<void> _saveUserData(Map<String, dynamic> responseData) async {
    final data = responseData["data"];
    
    await Localls.setdepatmentid(
      depatmentid: data["department"]?[0]?.toString() ?? "",
    );
    
    await Localls.setUserID(
      userId: data["_id"]?.toString() ?? "",
    );
    
    await Localls.setToken(
      token: responseData["token"]?.toString() ?? "",
    );

    // await Cachehelper().fetchDataandStoreLocaallly();
  }

  static void _handleErrorResponse(
      http.Response response, BuildContext context) {
    print('Failed: ${response.statusCode}, ${response.body}');
    final responseBody = response.body.toLowerCase();

    if (responseBody.contains("not exist") || response.statusCode == 404) {
      _showErrorAlert(
        context,
        title: "غير موجود".tr(),
        message: "لا يوجد مستخدم بهذا الرقم السري".tr(),
        icon: Icons.person_off,
      );
    } else if (responseBody.contains("active")) {
      _showWarningAlert(
        context,
        title: "غير مفعل".tr(),
        message: "هذا المستخدم موجود بالفعل لكن غير مفعل".tr(),
        icon: Icons.lock,
      );
    } else if (responseBody.contains("محظور") || responseBody.contains("blocked")) {
      _showErrorAlert(
        context,
        title: "انتبه".tr(),
        message: "هذا الجهاز محظور مؤقتاً راجع الادارة".tr(),
        icon: Icons.block,
      );
    } else if (responseBody.contains("<!doctype html>")) {
      _showInfoAlert(
        context,
        title: "مشكلة في السيرفر".tr(),
        message: "السيرفر لا يعمل حالياً، حاول لاحقاً".tr(),
        icon: Icons.cloud_off,
      );
    } else if (response.statusCode == 500) {
      _showErrorAlert(
        context,
        title: "خطأ في السيرفر".tr(),
        message: "حدث خطأ داخلي في السيرفر".tr(),
        icon: Icons.error,
      );
    } else if (response.statusCode == 401) {
      _showErrorAlert(
        context,
        title: "غير مصرح".tr(),
        message: "بيانات الدخول غير صحيحة".tr(),
        icon: Icons.security,
      );
    } else {
      _showErrorAlert(
        context,
        title: "فشل".tr(),
        message: "حدث خطأ غير متوقع (${response.statusCode})".tr(),
        icon: Icons.error_outline,
      );
    }
  }

  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading spinner مع التصميم الجديد
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: 

                  
                  CircularProgressIndicator(

                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    backgroundColor: secondaryColor.withOpacity(0.3),
                  )
                  
                  
                  ,
                ),
                const SizedBox(height: 20),
                Text(
                  "جاري تسجيل الدخول...".tr(),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "يرجى الانتظار".tr(),
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showSuccessAlert(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _showCustomAlert(
          context,
          title: "تم بنجاح".tr(),
          message: "تم تسجيل الدخول بنجاح".tr(),
          icon: Icons.check_circle,
          headerColor: primaryColor,
          iconColor: Colors.white,
        );
      }
    });
  }

  static void _showErrorAlert(BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    _showCustomAlert(
      context,
      title: title,
      message: message,
      icon: icon,
      headerColor: Colors.red,
      iconColor: Colors.white,
    );
  }

  static void _showWarningAlert(BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    _showCustomAlert(
      context,
      title: title,
      message: message,
      icon: icon,
      headerColor: Colors.orange,
      iconColor: Colors.white,
    );
  }

  static void _showInfoAlert(BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    _showCustomAlert(
      context,
      title: title,
      message: message,
      icon: icon,
      headerColor: Colors.blue,
      iconColor: Colors.white,
    );
  }

  static void _showCustomAlert(BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color headerColor,
    required Color iconColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 15,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header مع التدرج اللوني
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        headerColor.withOpacity(0.9),
                        headerColor,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(23),
                      topRight: Radius.circular(23),
                    ),
                  ),
                  child: Row(
                    children: [
                      // أيقونة داخل دائرة
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(icon, color: iconColor, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // محتوى الرسالة
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: primaryColor,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // عنصر زخرفي
                      Container(
                        height: 5,
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor,
                              secondaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // زر الإجراء
                Container(
                  padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shadowColor: accentColor.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "حسناً".tr(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.thumb_up, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}