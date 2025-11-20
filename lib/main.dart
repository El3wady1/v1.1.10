import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as f;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
// import 'package:saladafactory/features/DashBoard/loginDash/loginDashView.dart';
// import 'package:inventory/features/DashBoard/print_Barcode/presentation/view/printBarcodeView.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;

import 'features/login/presentation/controller/logincubit.dart';
import 'features/login/presentation/view/loginView.dart';
import 'features/splash/presentation/view/widgets/animated_splash.dart';
import 'core/utils/apiEndpoints.dart';
import 'core/utils/Strings.dart';
import 'features/helperApp/UpdateScreenView.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
/// ---------- BiometricController (singleton) ----------
class BiometricController {
  static const _prefKey = 'useBiometrics';
  static const _lastActivityKey = 'lastActivity';
  static final BiometricController _instance = BiometricController._internal();
  static BiometricController get instance => _instance;

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isAuthenticated = ValueNotifier<bool>(false);
  SharedPreferences? _prefs;
  bool _authInProgress = false;

  BiometricController._internal();

  static Future<void> init() => _instance._init();

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getBool(_prefKey) ?? false;
    enabled.value = saved;

    if (!enabled.value) {
      _isAuthenticated.value = true;
    }
  }

  Future<void> setEnabled(bool v) async {
    if (enabled.value == v) return; // تجنب التكرار

    enabled.value = v;
    await _prefs?.setBool(_prefKey, v);


    if (!v) {
      _isAuthenticated.value = true;
      _authInProgress = false;
      try {
        await LocalAuthentication().stopAuthentication();
      } catch (e) {
        debugPrint('Error stopping auth: $e');
      }
    } else {
      _isAuthenticated.value = false;
      _authInProgress = false;
    }
  }

  Future<void> toggle() async => setEnabled(!enabled.value);

  bool get isAuthenticated => _isAuthenticated.value;

  void setAuthenticated(bool value) {
    _isAuthenticated.value = value;
  }

  ValueNotifier<bool> get authNotifier => _isAuthenticated;

  void setAuthInProgress(bool value) {
    _authInProgress = value;
  }

  bool get authInProgress => _authInProgress;

  Future<void> updateLastActivity() async {
    await _prefs?.setInt(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);
  }

  int? get lastActivity => _prefs?.getInt(_lastActivityKey);

  bool get isSessionExpired {
    final last = lastActivity;
    if (last == null) return true;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = Duration(milliseconds: now - last);
    return diff.inSeconds > Strings.logoutTime;
  }

  Future<void> logout() async {
    _isAuthenticated.value = false;
    _authInProgress = false;
    await _prefs?.clear();
  }
}

/// ---------- SessionManager ----------
class SessionManager {
  static Timer? _sessionTimer;
  static final List<VoidCallback> _onTimeoutCallbacks = [];

  static void addTimeoutListener(VoidCallback callback) {
    _onTimeoutCallbacks.add(callback);
  }

  static void removeTimeoutListener(VoidCallback callback) {
    _onTimeoutCallbacks.remove(callback);
  }

  static void startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(Duration(milliseconds: Strings.logoutTime), () {
      for (final callback in _onTimeoutCallbacks) {
        callback();
      }
    });
  }

  static void resetTimer() {
    BiometricController.instance.updateLastActivity();
    startSessionTimer();
  }

  static void stopTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  static void dispose() {
    stopTimer();
    _onTimeoutCallbacks.clear();
  }
}

/// ---------- UpdateChecker ----------
class UpdateChecker {
  static Timer? _timer;
  static bool _isUpdating = false;
  static ValueChanged<bool>? _onUpdateStatusChanged;

  static void start({required ValueChanged<bool> onUpdateStatusChanged}) {
    _onUpdateStatusChanged = onUpdateStatusChanged;
    _timer = Timer.periodic( Duration(seconds: 2), (_) async {
      await _checkAppState();
    });
  }

  static Future<void> _checkAppState() async {
    try {
      final response = await http.get(
        Uri.parse(Apiendpoints.baseUrl + Apiendpoints.settings.appstate),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        bool updating = !(data["data"]["open"] ?? true);

        if (updating != _isUpdating) {
          _isUpdating = updating;
          _onUpdateStatusChanged?.call(_isUpdating);
        }
      }
    } catch (e) {
      debugPrint("Update check error: $e");
    }
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static bool get isUpdating => _isUpdating;
}

/// ---------- main ----------
void main() async {
    WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  await initializeDateFormatting('ar', null);

  tz.initializeTimeZones();

  // runApp(
  //   EasyLocalization(
  //     supportedLocales: [Locale('ar')],
  //     path: 'assets/translations', // مجلد ملفات الترجمة JSON أو CSV
  //     fallbackLocale: Locale('ar'),
  //     child: MaterialApp(
  //       debugShowCheckedModeBanner: false,
  //       home: Logindashview()),
  //   ),
  // );



  await BiometricController.init();

  bool shouldLogout = BiometricController.instance.isSessionExpired;
  if (shouldLogout) {
    await BiometricController.instance.logout();
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      child: MyApp(shouldLogout: shouldLogout),
    ),
  );
}

/// ---------- MyApp ----------
class MyApp extends StatefulWidget {
  final bool shouldLogout;

  const MyApp({this.shouldLogout = false, Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: BiometricGateOverlay(
        child: AppContent(shouldLogout: widget.shouldLogout),
      ),
    );
  }
}

/// ---------- BiometricGateOverlay ----------
class BiometricGateOverlay extends StatefulWidget {
  final Widget child;
  const BiometricGateOverlay({required this.child, Key? key}) : super(key: key);

  @override
  _BiometricGateOverlayState createState() => _BiometricGateOverlayState();
}

class _BiometricGateOverlayState extends State<BiometricGateOverlay>
    with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeAuthenticateOnStart());
  }

  Future<void> _maybeAuthenticateOnStart() async {
    if (!BiometricController.instance.enabled.value) {
      BiometricController.instance.setAuthenticated(true);
      return;
    }
    _authenticate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (BiometricController.instance.enabled.value) {
        BiometricController.instance.setAuthenticated(false);
        BiometricController.instance.setAuthInProgress(false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (BiometricController.instance.enabled.value &&
          !BiometricController.instance.isAuthenticated &&
          !BiometricController.instance.authInProgress) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (BiometricController.instance.isAuthenticated ||
        BiometricController.instance.authInProgress ||
        !BiometricController.instance.enabled.value) {
      return;
    }

    BiometricController.instance.setAuthInProgress(true);

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) {
        BiometricController.instance.setAuthenticated(true);
        BiometricController.instance.setAuthInProgress(false);
        return;
      }

      bool success = await _auth.authenticate(
        localizedReason: 'سجل الدخول باستخدام البصمة'.tr(),
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (!mounted) return;

      if (success) {
        BiometricController.instance.setAuthenticated(true);
        BiometricController.instance.setAuthInProgress(false);
        BiometricController.instance.updateLastActivity();
      } else {
        BiometricController.instance.setAuthInProgress(false);
        if (BiometricController.instance.enabled.value) {
          Future.delayed(const Duration(seconds: 7), _authenticate);
        }
      }
    } catch (e) {
      debugPrint('فشل المصادقة: $e');
      BiometricController.instance.setAuthInProgress(false);
      if (BiometricController.instance.enabled.value) {
        Future.delayed(const Duration(seconds: 7), _authenticate);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BiometricController.instance.authNotifier,
      builder: (context, isAuthenticated, _) {
        final showOverlay =
            BiometricController.instance.enabled.value && !isAuthenticated;
        return Scaffold(
          body: Stack(
            children: [
              widget.child,
              if (showOverlay)
                Positioned.fill(
                  child: Container(
                    color: Colors.black87,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          color: Colors.amber,
                          size: MediaQuery.of(context).size.width * .35,
                        ),

                        const SizedBox(height: 20),
                        Text(
                          "البصمة".tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'يرجى استخدام البصمة للوصول إلى التطبيق'.tr(),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 30),
                          width: double.infinity,
                          height: 45,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF74826A), Color(0xFF5A6B54)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF74826A).withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: _authenticate,
                            icon: Icon(Icons.fingerprint,
                                color: Colors.white, size: 20),
                            label: Text(
                              "ادخال البصمة".tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // TextButton(
                        //   onPressed: () {
                        //     // خيار لتعطيل البصمة من الشاشة
                        //     BiometricController.instance.setEnabled(false);
                        //   },
                        //   child: Text(
                        //     'تعطيل البصمة'.tr(),
                        //     style: const TextStyle(color: Colors.white70),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------- BiometricSwitch ----------

class BiometricSwitch extends StatefulWidget {
  final String title;
  final String subtitle;
  const BiometricSwitch(
      {this.title = 'استخدام البصمة', this.subtitle = '', Key? key})
      : super(key: key);

  @override
  _BiometricSwitchState createState() => _BiometricSwitchState();
}

class _BiometricSwitchState extends State<BiometricSwitch> {
  final ValueNotifier<bool> _notifier = BiometricController.instance.enabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _notifier,
      builder: (context, enabled, _) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(/*  */
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.subtitle.isNotEmpty)
                            const SizedBox(height: 4),
                          if (widget.subtitle.isNotEmpty)
                            Text(
                              widget.subtitle.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Switch(
                      value: enabled,
                      onChanged: (v) async {
                        print('Switch changed to: $v');
                        await BiometricController.instance.setEnabled(v);
                        setState(() {}); // إعادة بناء الواجهة فوراً

                        // عرض رسالة تأكيد
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              v ? 'تم تفعيل البصمة ✅'.tr() : 'تم تعطيل البصمة ❌'.tr(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: v ? Colors.green : Colors.blue,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: enabled ? Colors.green[50] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        enabled
                            ? Icons.fingerprint
                            : Icons.fingerprint_outlined,
                        color: enabled ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        enabled ? 'البصمة مفعلة'.tr() : 'البصمة معطلة'.tr(),
                        style: TextStyle(
                          color: enabled ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

/// ---------- LoginviewSesss ----------
class LoginviewSesss extends StatefulWidget {
  final bool showSessionExpired;

  const LoginviewSesss({this.showSessionExpired = false, Key? key})
      : super(key: key);

  @override
  _LoginviewSesssState createState() => _LoginviewSesssState();
}

class _LoginviewSesssState extends State<LoginviewSesss> {
  @override
  void initState() {
    super.initState();

    if (widget.showSessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSessionExpiredDialog();
      });
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("تنبيه".tr()),
        content: Text("تم انتهاء الجلسة، أعد تسجيل الدخول".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("موافق".tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Loginview(),
    );
  }
}

/// ---------- AppContent ----------
/// ---------- AppContent ----------
class AppContent extends StatefulWidget {
  final bool shouldLogout;

  const AppContent({this.shouldLogout = false, Key? key}) : super(key: key);

  @override
  State<AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<AppContent> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool isUpdating = false;
  Timer? _biometricCheckTimer; // ✅ مؤقت للتحقق من الخمول

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // إعداد نظام الجلسة
    _setupSessionManagement();
    
    // بدء التحقق من التحديثات
    _startUpdateChecker();
    
    // تحديث وقت النشاط الأولي
    BiometricController.instance.updateLastActivity();

    // ✅ تفعيل فحص النشاط كل دقيقة
    _biometricCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final last = BiometricController.instance.lastActivity;
      if (last != null && BiometricController.instance.enabled.value) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final diff = now - last;
        if (diff > Strings.logoutTime) {
          // مر أكثر من 30 دقيقة بدون نشاط
          await BiometricController.instance.logout();
          BiometricController.instance.setAuthenticated(false);
        }
      }
    });
  }

  void _setupSessionManagement() {
    // إضافة مستمع لانتهاء الجلسة
    SessionManager.addTimeoutListener(() async {
      if (mounted) {
        // إظهار رسالة انتهاء الجلسة
        _showSessionTimeoutDialog();
      }
    });

    // بدء تايمر الجلسة
    SessionManager.startSessionTimer();
  }

  void _showSessionTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("انتهت الجلسة".tr()),
        content: Text("لقد انتهت جلستك بسبب عدم النشاط. يرجى تسجيل الدخول مرة أخرى.".tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLoginWithSessionExpired();
            },
            child: Text("موافق".tr()),
          ),
        ],
      ),
    );
  }

  void _startUpdateChecker() {
    UpdateChecker.start(
      onUpdateStatusChanged: (updating) {
        if (mounted) {
          setState(() {
            isUpdating = updating;
          });
        }
      },
    );
  }



  @override
void didChangeAppLifecycleState(AppLifecycleState state) async {
  final LocalAuthentication auth = LocalAuthentication();

  if (state == AppLifecycleState.paused) {
    // التطبيق انتقل للخلفية → حفظ آخر وقت نشاط
    BiometricController.instance.updateLastActivity();
    return;
  }

  if (state == AppLifecycleState.resumed) {
    final last = BiometricController.instance.lastActivity;
    final now = DateTime.now().millisecondsSinceEpoch;
    const sessionDuration = 30 * 60 * 1000; // 30 دقيقة بالمللي ثانية

    if (last == null) {
      BiometricController.instance.updateLastActivity();
      return;
    }

    final diff = now - last;

    if (diff <= sessionDuration) {
      // لم تمر 30 دقيقة → إعادة ضبط الجلسة
      SessionManager.resetTimer();
      return;
    }

    // أكثر من 30 دقيقة → اطلب البصمة مباشرة
    bool canCheck = await auth.canCheckBiometrics;
    bool didAuthenticate = false;

    if (canCheck) {
      didAuthenticate = await auth.authenticate(
        localizedReason: 'الرجاء التحقق من هويتك للوصول للتطبيق',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    }

    if (didAuthenticate) {
      // نجحت البصمة → تحديث آخر نشاط
      BiometricController.instance.updateLastActivity();
      SessionManager.resetTimer();
    } else {
      // فشل التحقق → خروج المستخدم
      BiometricController.instance.logout();
      _navigateToLoginWithSessionExpired();
    }
  }
}

  // دالة التنقل لشاشة تسجيل الدخول مع رسالة انتهاء الجلسة
  void _navigateToLoginWithSessionExpired() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginviewSesss(showSessionExpired: true),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _biometricCheckTimer?.cancel(); // ✅ إلغاء التايمر عند الخروج
    SessionManager.dispose();
    UpdateChecker.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'سلطة فاكتوري'.tr(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        builder: (context, child) {
          return Directionality(
            textDirection: context.locale.languageCode == 'ar'
                ? f.TextDirection.rtl
                : f.TextDirection.ltr,
            child: isUpdating
                ? const UpdatingScreen()
                : Listener(
                    onPointerDown: (_) {
                      // إعادة تعيين تايمر الجلسة عند أي تفاعل
                      SessionManager.resetTimer();
                      BiometricController.instance.updateLastActivity();
                    },
                    child: child ?? const SizedBox.shrink(),
                  ),
          );
        },
        home: widget.shouldLogout
            ? const LoginviewSesss(showSessionExpired: true)
            : Animated_SplashView(),
      ),
    );
  }
}


//ِ؛××××××××××××××××××××××××××××
//---------------------------------------------------------------
// import 'package:flutter/material.dart' as flutter;
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:easy_localization/easy_localization.dart';
// // import 'package:inventory/features/DashBoard/loginDash/loginDashView.dart';
// import 'package:inventory/features/login/presentation/controller/logincubit.dart';
// import 'package:inventory/features/splash/presentation/view/widgets/animated_splash.dart';

// void main() async {
//   flutter.WidgetsFlutterBinding.ensureInitialized();
//   await EasyLocalization.ensureInitialized();
//   runApp(
//     EasyLocalization(
//       supportedLocales: [ flutter.Locale('en'),  flutter.Locale('ar')],
//       path: 'assets/lang',
//       fallbackLocale:  flutter.Locale('en'),
//       child: App(),
//     ),
//   );
// }

// class App extends flutter.StatelessWidget {
//   @override
//   flutter.Widget build(flutter.BuildContext context) {
//     return BlocProvider(
//       create: (_) => LoginCubit(),
//       child: flutter.MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'سلطة فاكتوري',
//         localizationsDelegates: context.localizationDelegates,
//         supportedLocales: context.supportedLocales,
//         locale: context.locale,
//         builder: (context, child) {
//           return flutter.Directionality(
//             textDirection: context.locale.languageCode == 'ar'
//                 ? flutter.TextDirection.rtl
//                 : flutter.TextDirection.ltr,
//             child: child!,
//           );
//         },
//         // home: Logindashview(),
//       home: Animated_SplashView(),
//       ),
//       );
//   }
// }

// //Dash
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart'as flutter;
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:inventory/features/DashBoard/loginDash/loginDashView.dart';
// import 'package:inventory/features/login/presentation/controller/logincubit.dart';
// import 'package:inventory/features/splash/presentation/view/widgets/animated_splash.dart';
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';

// void main() async{
//    flutter.WidgetsFlutterBinding.ensureInitialized();
//   await EasyLocalization.ensureInitialized();
//     await initializeDateFormatting('ar', null);

//   runApp(App());
// }

// class App extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => LoginCubit(),
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'لوحة تحكم سلطة فاكتوري',
//         builder: (context, child) {
//           return Directionality(
//             textDirection: flutter.TextDirection.ltr, // أو TextDirection.rtl لو عايز العربية
//             child: child!,
//           );
//         },
//         // home: Logindashview(),
//         home: Animated_SplashView(),
//       ),
//     );
//   }
// }