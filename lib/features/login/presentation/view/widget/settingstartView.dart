import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:saladafactory/core/app_router.dart';
import 'package:saladafactory/features/helperApp/Basma/activeBasma.dart';
import 'package:saladafactory/features/privacy/view/privacyView.dart';
import 'package:saladafactory/features/profile/presentation/widget/languageDropdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

/// ---------- BiometricController (singleton) ----------
class BiometricController {
  static const _prefKey = 'useBiometrics';
  static final BiometricController _instance = BiometricController._internal();
  static BiometricController get instance => _instance;

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isAuthenticated = ValueNotifier<bool>(false);
  SharedPreferences? _prefs;

  BiometricController._internal();

  static Future<void> init() => _instance._init();

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getBool(_prefKey) ?? true;
    enabled.value = saved;
    
    // إذا كانت البصمة معطلة، اعتبر المستخدم مصادق عليه
    if (!enabled.value) {
      _isAuthenticated.value = true;
    }
  }

  Future<void> setEnabled(bool v) async {
    enabled.value = v;
    await _prefs?.setBool(_prefKey, v);
    
    // إذا تم تعطيل البصمة، اعتبر المستخدم مصادق عليه
    if (!v) {
      _isAuthenticated.value = true;
    } else {
      // إذا تم تشغيل البصمة، ابدأ عملية المصادقة
      _isAuthenticated.value = false;
      _triggerAuthentication();
    }
  }

  Future<void> toggle() async => setEnabled(!enabled.value);

  bool get isAuthenticated => _isAuthenticated.value;
  
  void setAuthenticated(bool value) {
    _isAuthenticated.value = value;
  }

  ValueNotifier<bool> get authNotifier => _isAuthenticated;

  // دالة لتفعيل المصادقة الحيوية
  Future<void> _triggerAuthentication() async {
    if (!enabled.value) return;
    
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticate = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canAuthenticate || !isDeviceSupported) {
        _isAuthenticated.value = true;
        return;
      }

      final bool success = await auth.authenticate(
        localizedReason: 'سجل الدخول باستخدام البصمة'.tr(),
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      _isAuthenticated.value = success;
    } catch (e) {
      debugPrint('فشل المصادقة: $e');
      _isAuthenticated.value = false;
    }
  }

  // دالة لإعادة تعيين المصادقة (للاستخدام عند الخروج من التطبيق)
  void resetAuthentication() {
    if (enabled.value) {
      _isAuthenticated.value = false;
    }
  }
}

/// ---------- BiometricGateOverlay ----------
class BiometricGateOverlay extends StatefulWidget {
  final Widget child;
  const BiometricGateOverlay({required this.child, Key? key}) : super(key: key);

  @override
  _BiometricGateOverlayState createState() => _BiometricGateOverlayState();
}

class _BiometricGateOverlayState extends State<BiometricGateOverlay> with WidgetsBindingObserver {
  bool _authInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialAuth();
  }

  void _checkInitialAuth() {
    if (!BiometricController.instance.enabled.value) {
      BiometricController.instance.setAuthenticated(true);
    } else {
      _triggerAuthentication();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // عندما يخرج المستخدم من التطبيق، إعادة تعيين حالة المصادقة
      if (BiometricController.instance.enabled.value) {
        BiometricController.instance.resetAuthentication();
      }
    } else if (state == AppLifecycleState.resumed) {
      // عندما يعود المستخدم للتطبيق، ابدأ المصادقة إذا كانت مفعلة
      if (BiometricController.instance.enabled.value && 
          !BiometricController.instance.isAuthenticated) {
        _triggerAuthentication();
      }
    }
  }

  Future<void> _triggerAuthentication() async {
    if (BiometricController.instance.isAuthenticated || 
        _authInProgress || 
        !BiometricController.instance.enabled.value) return;
    
    setState(() {
      _authInProgress = true;
    });

    try {
      final LocalAuthentication auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) {
        BiometricController.instance.setAuthenticated(true);
        setState(() {
          _authInProgress = false;
        });
        return;
      }

      bool success = await auth.authenticate(
        localizedReason: 'سجل الدخول باستخدام البصمة'.tr(),
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (!mounted) return;

      if (success) {
        BiometricController.instance.setAuthenticated(true);
        setState(() {
          _authInProgress = false;
        });
      } else {
        setState(() {
          _authInProgress = false;
        });
        // إعادة المحاولة بعد فشل المصادقة
        Future.delayed(const Duration(milliseconds: 500), _triggerAuthentication);
      }
    } catch (e) {
      debugPrint('فشل المصادقة: $e');
      setState(() {
        _authInProgress = false;
      });
      // إعادة المحاولة بعد الخطأ
      Future.delayed(const Duration(milliseconds: 500), _triggerAuthentication);
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
        final showOverlay = BiometricController.instance.enabled.value && !isAuthenticated;
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
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'المصادقة مطلوبة'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'يرجى استخدام البصمة للوصول إلى التطبيق'.tr(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: _triggerAuthentication,
                          child: Text(
                            'إعادة المحاولة'.tr(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
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

/// ---------- Settingstartview ----------
class Settingstartview extends StatefulWidget {
  const Settingstartview({super.key});

  @override
  _SettingstartviewState createState() => _SettingstartviewState();
}

class _SettingstartviewState extends State<Settingstartview> {
  final Color _primaryColor = const Color(0xFF74826A);
  final Color _accentColor = const Color(0xFFEDBE2C);
  final Color _secondaryColor = const Color(0xFFCDBCA2);
  final Color _backgroundColor = const Color(0xFFF3F4EF);

  late final ValueNotifier<bool> _biometricNotifier;

  @override
  void initState() {
    super.initState();
    _biometricNotifier = BiometricController.instance.enabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "الإعدادات".tr(),
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.06,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            InkWell(
              onTap: (){
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ActiveBasma()),
                  );
              },
              child:             _buildBiometricCard(),
)
            , SizedBox(height: 20),
            _buildLanguageCard(),
            const SizedBox(height: 20),
            _buildAuthStatusCard(),
                        const SizedBox(height: 20),
InkWell(
  onTap: (){
    Routting.push(context, Privacyview());
  },
  child: _buildPrivacyCard())
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: _biometricNotifier,
      builder: (context, enabled, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: _secondaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.fingerprint, color: _accentColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "بصمة الدخول".tr(),
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
           
                  ],
                ),
              ),
         
           
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: _secondaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.language, color: _primaryColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "اللغة :".tr(),
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LanguageDropdown(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthStatusCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: BiometricController.instance.authNotifier,
      builder: (context, isAuthenticated, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _biometricNotifier,
          builder: (context, enabled, _) {
            if (!enabled) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'البصمة معطلة - يمكن الوصول للتطبيق مباشرة'.tr(),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAuthenticated ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAuthenticated ? Colors.green[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAuthenticated ? Icons.verified : Icons.pending,
                    color: isAuthenticated ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuthenticated ? 'مصادق بنجاح'.tr() : 'في انتظار المصادقة'.tr(),
                          style: TextStyle(
                            color: isAuthenticated ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAuthenticated 
                              ? 'يمكنك استخدام التطبيق بشكل آمن'.tr()
                              : 'يرجى استخدام البصمة للوصول إلى التطبيق'.tr(),
                          style: TextStyle(
                            color: isAuthenticated ? Colors.green[700] : Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

Widget _buildPrivacyCard(){
 return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: _secondaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.privacy_tip, color: _primaryColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                   'سياسة الخصوصية'.tr(),
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
 
}

}