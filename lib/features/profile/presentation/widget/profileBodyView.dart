import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/features/profile/presentation/widget/languageDropdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saladafactory/features/login/presentation/view/loginView.dart';

class Profilebodyview extends StatelessWidget {
  final Map<String, dynamic> userData;

  const Profilebodyview({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF74826A); // Updated primary color

    return Scaffold(
      backgroundColor: Color(0xFFF3F4EF), // Light cream

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFF3F4EF), // Light cream

        title: Text(
          "بروفايلي".tr(),
          style: GoogleFonts.cairo(),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج'.tr(),
            onPressed: () async {
              SharedPreferences pref = await SharedPreferences.getInstance();
              await pref.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Loginview()),
              );
              showTrueSnackBar(
                  context: context,
                  message: "تم تسجيل الخروج".tr(),
                  icon: Icons.logout);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 3,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: const Color(0xFFCDBCA2)
                      .withOpacity(0.3), // Updated circle background
                  child: userData['profileImg'] != null &&
                          userData['profileImg'] != 'no profileImg'.tr()
                      ? ClipOval(
                          child: Image.network(
                            userData['profileImg'],
                            width: 130,
                            height: 130,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.person,
                                size: 70,
                                color: primaryColor),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 70,
                          color: primaryColor,
                        ),
                ),
              ),
              const SizedBox(height: 25),

              Text(
                textAlign: TextAlign.center,
                userData['name'] ?? 'لم يتم توفير اسم'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: userData['role'] == 'user'.tr()
                      ? const Color(0xFF74826A)
                          .withOpacity(0.15) // Updated color
                      : const Color(0xFFEDBE2C)
                          .withOpacity(0.15), // Updated color
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: userData['role'] == 'user'.tr()
                        ? const Color(0xFF74826A)
                            .withOpacity(0.3) // Updated color
                        : const Color(0xFFEDBE2C)
                            .withOpacity(0.3), // Updated color
                    width: 1,
                  ),
                ),
                child: Text(
                  userData['role'] == 'user' ? 'مستخدم عادي'.tr() : 'مدير'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: userData['role'] == 'user'
                        ? const Color(0xFF74826A) // Updated color
                        : const Color(0xFFEDBE2C), // Updated color
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildInfoCard(context),
              const SizedBox(height: 30),

              // عرض الأقسام
              _buildDepartmentsSection(),
             
             
             
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "اللغة :".tr(),
                      style: GoogleFonts.cairo(fontSize: 16),
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LanguageDropdown(),
                  )
                ],
              ),
         
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      shadowColor: theme.primaryColor.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4EF), // Updated card background
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildInfoRow(
                  Icons.phone_iphone_outlined,
                  'رقم الهاتف'.tr(),
                  userData['phone'] ?? 'لم يتم توفيره'.tr(),
                  const Color(0xFF74826A)), // Updated color
              const Divider(height: 24, thickness: 0.8),
              _buildInfoRow(
                  Icons.verified_user_outlined,
                  'حالة الحساب'.tr(),
                  userData['isVerified'] ? 'مفعل'.tr() : 'غير مفعل'.tr(),
                  userData['isVerified']
                      ? const Color(0xFF74826A)
                      : const Color(0xFFEDBE2C)), // Updated colors
              const Divider(height: 24, thickness: 0.8),
              _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'تاريخ إنشاء الحساب'.tr(),
                  _formatDate(userData['createdAt']),
                  const Color(0xFFCDBCA2)), // Updated color
              const Divider(height: 24, thickness: 0.8),
              _buildInfoRow(
                  Icons.update_outlined,
                  'آخر تحديث'.tr(),
                  _formatDate(userData['updatedAt']),
                  const Color(0xFF74826A)), 
                  
                   _buildInfoRow(
                  Icons.app_shortcut_rounded,
                  "الاصدار :".tr(),
                 (userData['Appversion']),
                  const Color(0xFF74826A)), // Updated color
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentsSection() {
    final List departments = userData['department'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأقسام المرتبطة:'.tr(),
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF74826A), // Updated color
          ),
        ),
        const SizedBox(height: 10),
        if (departments.isEmpty)
          Text(
            'لا يوجد أقسام مرتبطة'.tr(),
            style: GoogleFonts.cairo(fontSize: 14),
          )
        else
          Column(
            children: departments.map<Widget>((dept) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.apartment_outlined,
                        size: 20,
                        color: const Color(0xFF74826A)), // Updated color
                    const SizedBox(width: 10),
                    Text(
                      dept['name'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      final monthNames = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      return '${monthNames[date.month - 1]} ${date.day}, ${date.year} الساعة ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
