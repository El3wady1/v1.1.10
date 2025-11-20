// import 'dart:io';
// import 'package:flutter/services.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> init() async {
//     if (Platform.isAndroid) {
//       final status = await Permission.notification.status;
//       if (!status.isGranted) {
//         await Permission.notification.request();
//       }
//     }

//     const AndroidInitializationSettings androidInit =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const IOSInitializationSettings iosInit = IOSInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );

//     const InitializationSettings initSettings = InitializationSettings(
//       android: androidInit,
//       iOS: iosInit,
//     );

//     await _notificationsPlugin.initialize(initSettings);
//   }

//   /// نسخ صورة من assets إلى ملف مؤقت
//   static Future<String> _copyAssetToFile(String assetPath, String filename) async {
//     final byteData = await rootBundle.load(assetPath);
//     final file = File('${(await getTemporaryDirectory()).path}/$filename');
//     await file.writeAsBytes(byteData.buffer.asUint8List());
//     return file.path;
//   }

//   /// إرسال إشعار مع صورة (Android) وattachment (iOS)
//   static Future<void> showNotification({
//     required String title,
//     required String body,
//   }) async {
//     if (Platform.isAndroid) {
//       // صورة Android
//       final imagePath = await _copyAssetToFile(
//         'assets/icon/logoosalat.png',
//         'logoosalat.png',
//       );

//       final bigPictureStyle = BigPictureStyleInformation(
//         FilePathAndroidBitmap(imagePath),
//         largeIcon: FilePathAndroidBitmap(imagePath),
//         contentTitle: title,
//         summaryText: body,
//         hideExpandedLargeIcon: false,
//       );

//       final androidDetails = AndroidNotificationDetails(
//         'logout_channel',
//         'Logout Notifications',
//         channelDescription: 'Notifications for auto logout',
//         importance: Importance.max,
//         priority: Priority.high,
//         styleInformation: bigPictureStyle,
//         enableVibration: true,
//       );

//       final notificationDetails = NotificationDetails(android: androidDetails);
//       await _notificationsPlugin.show(0, title, body, notificationDetails);
//     } else if (Platform.isIOS) {
//       // iOS attachment
//       final imagePath = await _copyAssetToFile(
//         'assets/icon/logoosalat.png',
//         'logoosalat.png',
//       );

//       final iosAttachment = IOSNotificationAttachment(imagePath);

//       final iosDetails = IOSNotificationDetails(
//         attachments: [iosAttachment],
//       );

//       final notificationDetails = NotificationDetails(iOS: iosDetails);
//       await _notificationsPlugin.show(0, title, body, notificationDetails);
//     }
//   }
// }
