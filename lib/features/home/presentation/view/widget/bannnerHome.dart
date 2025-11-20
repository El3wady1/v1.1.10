import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:saladafactory/features/home/data/repo/ReturnLastloginRepo.dart';

class Bannnerhome extends StatefulWidget {
  const Bannnerhome({super.key});

  @override
  State<Bannnerhome> createState() => _BannerHomeState();
}

class _BannerHomeState extends State<Bannnerhome> {
  // نظام الألوان
  static const Color primaryDark = Color(0xFF74826A); // الأخضر الغامق
  static const Color accent = Color(0xFFEDBE2C); // الذهبي
  static const Color neutral = Color(0xFFCDBCA2); // البيج الفاتح
  static const Color background = Color(0xFFF3F4EF); // الكريمي الفاتح

  Map<String, dynamic>? _userData;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // إضافة دالة للتأكد من أن الـ widget ما زال mounted
  bool get isMounted => mounted;

  Future<void> _loadUserData() async {
    if (!isMounted) return;
    
    setState(() => _isLoading = true);

    try {
      final data = await ReturnLastloginRepo.featchData();
      if (!isMounted) return;
      await _cacheUserData(data);
      setState(() => _userData = data);
    } catch (e) {
      if (!isMounted) return;
      await _handleError(e);
    } finally {
      if (isMounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cacheUserData(Map<String, dynamic>? data) async {
    if (data == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedUserData', jsonEncode(data));
  }

  Future<void> _handleError(dynamic error) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cachedUserData');

    if (cached != null) {
      setState(() => _userData = jsonDecode(cached));
    } else {
      setState(() {
        _errorMessage = error is SocketException
            ? 'لا يوجد اتصال بالإنترنت'.tr()
            : 'حدث خطأ في جلب البيانات'.tr();
      });
    }
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return 'غير معروف'.tr();

    try {
      DateTime parsedDate;

      if (date is String) {
        parsedDate = DateTime.parse(date).toUtc();
      } else if (date is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(date, isUtc: true);
      } else {
        return 'غير معروف'.tr();
      }

      // تحويل لتوقيت المدينة المنورة (Asia/Riyadh)
      final location = tz.getLocation('Asia/Riyadh');
      final tzDateTime = tz.TZDateTime.from(parsedDate, location);

      // صياغة التاريخ (7-7-2020) + الوقت (3:30 PM)
      final dateFormat = DateFormat('d-M-yyyy', context.locale.languageCode);
      final timeFormat = DateFormat.jm(context.locale.languageCode);

      return "${dateFormat.format(tzDateTime)} - ${timeFormat.format(tzDateTime)}";
    } catch (e) {
      return 'غير معروف'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget(width);
    }

    if (_userData == null) {
      return _buildNoDataWidget();
    }

    return _buildUserBanner(width);
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: primaryDark,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(double width) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 32, color: accent),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('إعادة المحاولة'.tr(), style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Text(
        'لا توجد بيانات متاحة'.tr(),
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: neutral.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildUserBanner(double width) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.5),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: neutral.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: neutral.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryDark.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person_outline,
              size: 28,
              color: primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${"مرحباً بك".tr()}, ${_userData!['name'] ?? 'مستخدم'.tr()}!',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${"آخر دخول:".tr()} ${_formatDateTime(_userData!['lastLogin'])}',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryDark.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // يمكن إضافة أي تنظيف إضافي هنا إذا لزم الأمر
    super.dispose();
  }
}