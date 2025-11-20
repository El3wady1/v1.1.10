// import 'package:flutter/material.dart';
// import 'package:local_auth/local_auth.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class BiometricHelper {
//   static final LocalAuthentication _auth = LocalAuthentication();

//   /// دالة التحقق بالبصمة (ترجع true لو تم التحقق بنجاح)
//   static Future<bool> checkBiometric(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     bool useBiometric = prefs.getBool('useBiometric') ?? false;

//     if (!useBiometric) return true; // لو المستخدم مش مفعل البصمة، نكمل عادي

//     try {
//       bool authenticated = await _auth.authenticate(
//         localizedReason: 'الرجاء تأكيد الهوية باستخدام بصمة الإصبع',
//         options: const AuthenticationOptions(
//           biometricOnly: true,
//           stickyAuth: true,
//         ),
//       );

//       if (!authenticated) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('فشل التحقق بالبصمة ❌'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }

//       return authenticated;
//     } catch (e) {
//       debugPrint("Biometric Error: $e");
//       return false;
//     }
//   }
// }
