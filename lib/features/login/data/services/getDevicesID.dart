import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:saladafactory/core/utils/Strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();

  // تحقق إذا كان تم حفظ UUID مسبقًا
  String? storedId = prefs.getString(Strings.DeviceID);
  if (storedId != null) return storedId;

  String deviceId;

  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceId = androidInfo.id ?? const Uuid().v4(); // ANDROID_ID أو UUID
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor ?? const Uuid().v4();
  } else {
    deviceId = const Uuid().v4(); // fallback لأي منصة أخرى
  }

  // احفظه محليًا لاستخدامه لاحقًا
  await prefs.setString('device_id', deviceId);

  return deviceId;
}
