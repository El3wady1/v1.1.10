import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:saladafactory/core/utils/apiEndpoints.dart';

class Active30minorderproductionservices {
 static var baseurl=Apiendpoints.baseUrl;

 static Future make() async {
  final url = Uri.parse(baseurl+Apiendpoints.settings.makeactive_30minOrderProduction);

  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "start": true,
      }),
    ).timeout(Duration(minutes: 10));

    if (response.statusCode == 200||response.statusCode == 201){
      final data = jsonDecode(response.body);
      print('✅data successfully: $data');
    } else {
      print('❌ Failed ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('⚠️ Error: $e');
  }
}
static Future get()async{
  try {
    final response = await http.get(
      Uri.parse(baseurl+Apiendpoints.settings.getactive_30minOrderProduction),).timeout(Duration(minutes: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      print('✅ Success: $data');
    return data;
    } else {
      print('❌ Error: ${response.statusCode}');
      print('Response: ${response.body}');
   return null;
    }
  } catch (e) {
    print('⚠️ Exception: $e');
  }
}

}
