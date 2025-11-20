import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceName() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return "${androidInfo.manufacturer} ${androidInfo.model}"; 
    // مثال: Samsung Galaxy S21
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return iosInfo.name ?? iosInfo.model ?? "iOS Device";
    // مثال: John's iPhone أو iPhone 14
  } else {
    return "Unknown Device";
  }
}
