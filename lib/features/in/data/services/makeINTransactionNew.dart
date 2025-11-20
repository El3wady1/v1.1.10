import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/Widgets/showsnackbar.dart';
import '../../../../core/utils/apiEndpoints.dart';



class ServiceIN{
  
 static Future<Map<String, dynamic>> addInTransactionNew({
  required String productID,
  required String userID,
  required BuildContext context,
}) async {
  try {
     String apiUrl =Apiendpoints.baseUrl+Apiendpoints.transaction.add;

    final Map<String, dynamic> requestBody = {
      "productID": productID,
      "type": "IN",
      "userID": userID,
      "note": "تمت إضافة منتج جديد",
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
        showTrueSnackBar(
          context: context, 
          message: 'تم رفع الصنف بنجاح', 
          icon: Icons.check,
        );    
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    
    } else {
      return {
        'success': false,
        'error': 'Failed with status: ${response.statusCode}',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
}