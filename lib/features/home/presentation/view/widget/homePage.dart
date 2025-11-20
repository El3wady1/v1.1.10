import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/app_router.dart';
import 'package:saladafactory/core/utils/Strings.dart';
import 'package:saladafactory/core/utils/assets.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:saladafactory/features/compilations/presentation/view/compilationsView.dart';
import 'package:saladafactory/features/home/data/repo/ReturnLastloginRepo.dart';
import 'package:saladafactory/features/home/presentation/view/widget/bannnerHome.dart';
import 'package:saladafactory/features/home/presentation/view/widget/cardhome.dart';
import 'package:saladafactory/features/login/presentation/view/loginView.dart';
import 'package:saladafactory/features/orderProduction/data/services/active_30minOrderProductionServices.dart';
import 'package:saladafactory/features/orderSupply/data/services/active_30minOrderSupplyServices.dart';
import 'package:saladafactory/features/recive/presentation/view/reciveView.dart';
import 'package:saladafactory/features/rezo/presentation/view/widget/rezoBodyView.dart';
import 'package:saladafactory/features/scanBarCode/presentation/view/scanbarCodeView.dart';
import 'package:saladafactory/features/send/presentation/view/sendView.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../orderProduction/presentation/view/orderProduction.dart';
import '../../../../orderSupply/presentation/view/widget/orderSupplyBody.dart';
import '../../../../out/presentation/view/widget/outBodyView.dart';
import '../../../../production/presentation/view/productionView.dart';
import 'package:saladafactory/features/compilations/presentation/view/widget/allWasted.dart';

import '../../../../rezo/presentation/view/rezoView.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userData;
  final String _userDataKey = 'cached_user_data';
  Timer? _refreshTimer;
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _startConnectivityListener();
    loadUserData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      loadUserData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      final newOnlineStatus = result != ConnectivityResult.none;

      if (newOnlineStatus != _isOnline) {
        setState(() {
          _isOnline = newOnlineStatus;
        });

        // إظهار رسالة عند تغيير حالة الاتصال
        if (newOnlineStatus) {
          showTrueSnackBar(
            context: context,
            message: "تم الاتصال بالإنترنت".tr(),
            icon: Icons.wifi,
          );
        } else {
          showfalseSnackBar(
            context: context,
            message: "لا يوجد اتصال بالإنترنت".tr(),
            icon: Icons.wifi_off,
          );
        }
      }
    });
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    if (_isOnline) {
      try {
        final data = await ReturnLastloginRepo.featchData();
        await prefs.setString(_userDataKey, jsonEncode(data));
        if (mounted) {
          setState(() {
            userData = data;
          });
        }
      } catch (e) {
        // في حالة الخطأ، استخدام البيانات المخزنة محلياً
        final cached = prefs.getString(_userDataKey);
        if (cached != null && mounted) {
          setState(() {
            userData = jsonDecode(cached);
          });
        }
      }
    } else {
      // لا يوجد اتصال، استخدام البيانات المخزنة محلياً فقط
      final cached = prefs.getString(_userDataKey);
      if (cached != null && mounted) {
        setState(() {
          userData = jsonDecode(cached);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final userName = userData?["name"] ?? "مستخدم";
    final canAddProduct = userData?["canAddProduct"] ?? false;
    final canRemoveProduct = userData?["canRemoveProduct"] ?? false;
    final canProduction = userData?["canProduction"] ?? false;
    final canOrderProduction = userData?["canOrderProduction"] ?? false;
    final canReceive = userData?["canReceive"] ?? false;
    final canSend = userData?["canSend"] ?? false;
    final canSupply = userData?["canSupply"] ?? false;
    final canDamaged = userData?["canDamaged"] ?? false;
    final canEditLastSupply = userData?["canEditLastSupply"] ?? false;
    final canEditLastOrderProduction =
        userData?["canEditLastOrderProduction"] ?? false;
    final canShowTawalf = userData?["canShowTawalf"] ?? false;
    final canaddRezoCahser = userData?["canaddRezoCahser"] ?? false;

    const Color primaryDark = Color(0xFF74826A); // Dark green
    const Color accent = Color(0xFFEDBE2C); // Gold/yellow
    const Color neutral = Color(0xFFCDBCA2); // Beige
    const Color background = Color(0xFFF3F4EF); // Light cream

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: background,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AssetIcons.logo, width: 35, height: 35),
            const SizedBox(width: 5),
            Text(
              Strings.appName.tr(),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          // مؤشر حالة الاتصال
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: _isOnline ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج'.tr(),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              bool useBiometric = prefs.getBool('useBiometric') ?? false;
              await prefs.clear();
              await prefs.setBool('useBiometric', useBiometric);

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Loginview()),
                );
                showTrueSnackBar(
                  context: context,
                  message: "تم تسجيل الخروج".tr(),
                  icon: Icons.logout,
                );
              }
            },
          ),
        ],
      ),
      body: !_isOnline
          ? Container(
              child: Center(
                child: Text(
                  "لا يوجد اتصال بالإنترنت".tr(),
                  style: GoogleFonts.cairo(),
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رسالة عدم الاتصال بالإنترنت
                  if (!_isOnline) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "لا يوجد اتصال بالإنترنت".tr(),
                              style: GoogleFonts.cairo(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Center(
                    child: Text(
                      "الرئيسية".tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Bannnerhome(),
                  SizedBox(height: height * 0.03),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: width < 600 ? 2 : 4,
                      childAspectRatio: 1.1,
                      mainAxisSpacing: width * 0.05,
                      crossAxisSpacing: width * 0.05,
                      children: [
                        if (canAddProduct)
                          Cardhome(
                            icon: Icons.add_box,
                            title: 'إدخال صنف'.tr(),
                            color: Colors.green.shade700,
                            onTap: () {
                              if (!_isOnline) {
                                showfalseSnackBar(
                                  context: context,
                                  message: "لا يوجد اتصال بالإنترنت".tr(),
                                  icon: Icons.wifi_off,
                                );
                                return;
                              }
                              Routting.push(
                                context,
                                ScanbarcodeInview(mainProduct: ""),
                              );
                            },
                          ),
                        if (canRemoveProduct)
                          Cardhome(
                            icon: Icons.indeterminate_check_box,
                            title: 'إخراج صنف'.tr(),
                            color: Colors.red.shade700,
                            onTap: () {
                              if (!_isOnline) {
                                showfalseSnackBar(
                                  context: context,
                                  message: "لا يوجد اتصال بالإنترنت".tr(),
                                  icon: Icons.wifi_off,
                                );
                                return;
                              }
                              Routting.push(context, Outbodyview());
                            },
                          ),
                        if (canReceive)
                          Cardhome(
                            icon: Icons.inventory,
                            title: 'استلام'.tr(),
                            color: Colors.blue.shade700,
                            onTap: () {
                              if (!_isOnline) {
                                showfalseSnackBar(
                                  context: context,
                                  message: "لا يوجد اتصال بالإنترنت".tr(),
                                  icon: Icons.wifi_off,
                                );
                                return;
                              }
                              Routting.push(context, Reciveview());
                            },
                          ),
                        if (canSend)
                          Cardhome(
                            icon: Icons.send_and_archive_outlined,
                            title: 'ارسال'.tr(),
                            color: Colors.purple.shade700,
                            onTap: () {
                              if (!_isOnline) {
                                showfalseSnackBar(
                                  context: context,
                                  message: "لا يوجد اتصال بالإنترنت".tr(),
                                  icon: Icons.wifi_off,
                                );
                                return;
                              }
                              Routting.push(context, Sendview());
                            },
                          ),
                        if (canSupply)
                          Cardhome(
                            icon: Icons.local_shipping,
                            title: "توريد".tr(),
                            color: Colors.purple.shade700,
                            onTap: () async {
                              if (!_isOnline) {
                                showfalseSnackBar(
                                  context: context,
                                  message: "لا يوجد اتصال بالإنترنت".tr(),
                                  icon: Icons.wifi_off,
                                );
                                return;
                              }
                              var usercanedite;
                              await Active30minordersupplyservices.get().then(
                                (v) => usercanedite = v["data"]?["open"],
                              );
                              Routting.push(
                                context,
                                OrderSupplyBody(
                                  canedit: canEditLastSupply,
                                  usercanedite: usercanedite,
                                ),
                              );
                            },
                          ),
                        if (canOrderProduction)
                          Cardhome(
                            icon: Icons.receipt_long,
                            title: "طلب إنتاج".tr(),
                            color: Colors.orange.shade700,
                            onTap: () async {
                              if (!_isOnline) {
                                showfalseSnackBar(
                                  context: context,
                                  message: "لا يوجد اتصال بالإنترنت".tr(),
                                  icon: Icons.wifi_off,
                                );
                                return;
                              }
                              var usercanedite;
                              await Active30minorderproductionservices.get()
                                  .then(
                                    (v) => usercanedite = v["data"]?["open"],
                                  );
                              print(usercanedite);
                              if (usercanedite != null) {
                                Routting.push(
                                  context,
                                  Orderproduction(
                                    canedit: canEditLastOrderProduction,
                                    usercanedite: usercanedite,
                                  ),
                                );
                              } else {
                                showfalseSnackBar(
                                  context: context,
                                  message: "لا يوجد اتصال بالإنترنت".tr(),
                                  icon: Icons.network_wifi_1_bar,
                                );
                              }
                            },
                          ),
                        if (canProduction)
                          Cardhome(
                            icon: Icons.precision_manufacturing,
                            title: "إنتاج".tr(),
                            color: Colors.teal.shade700,
                            onTap: () async {
                              if (!_isOnline) {
                                showfalseSnackBar(
                                  context: context,
                                  message: "لا يوجد اتصال بالإنترنت".tr(),
                                  icon: Icons.wifi_off,
                                );
                                return;
                              }
                              var role;
                              await Localls.getrole().then(
                                (value) => role = value,
                              );
                              print(role);
                              Routting.push(
                                context,
                                Productionview(role: role),
                              );
                            },
                          ),
                        if (canDamaged)
                          Cardhome(
                            icon: Icons.delete_forever,
                            title: "التوالف".tr(),
                            color: Colors.grey.shade800,
                            onTap: () {
                              if (!_isOnline) {
                                showfalseSnackBar(
                                  context: context,
                                  message: "لا يوجد اتصال بالإنترنت".tr(),
                                  icon: Icons.wifi_off,
                                );
                                return;
                              }
                              Routting.push(context, Compilationsview());
                            },
                          ),
                        if (canShowTawalf)
                          Cardhome(
                            icon: Icons.cleaning_services,
                            title: "التوالف مفصل".tr(),
                            color: Colors.grey.shade800,
                            onTap: () {
                              if (!_isOnline) {
                                showfalseSnackBar(
                                  context: context,
                                  message: "لا يوجد اتصال بالإنترنت".tr(),
                                  icon: Icons.wifi_off,
                                );
                                return;
                              }
                              Routting.push(context, Allwasted());
                            },
                          ),

                        if (canaddRezoCahser)
                          Cardhome(
                            icon: Icons.money,
                            title: "ريزو كاشير".tr(),
                            color: Colors.grey.shade800,
                            onTap: () {
                              if (!_isOnline) {
                                showfalseSnackBar(
                                  context: context,
                                  message: "لا يوجد اتصال بالإنترنت".tr(),
                                  icon: Icons.wifi_off,
                                );
                                return;
                              }
                              Routting.push(context, Rezoview());
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
