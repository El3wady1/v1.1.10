import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class Privacyview extends StatelessWidget {
  final Color primaryColor = const Color(0xFF74826A); // الأخضر الترابي
  final Color accentColor = const Color(0xFFEDBE2C); // الأصفر الذهبي
  final Color secondaryColor = const Color(0xFFCDBCA2); // البيج الفاتح
  final Color backgroundColor = const Color(0xFFF3F4EF); // الكريمي الفاتح

  const Privacyview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'سياسة الخصوصية'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: secondaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.privacy_tip_outlined,
                        size: 40,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'مرحبًا بكم في تطبيق اداره التشغيل - شركة ار زو'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'نظام متكامل لإدارة التشغيل و طلبات الفروع'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Privacy Policy Content
              _buildPolicySection(
                icon: Icons.security,
                title: 'حماية خصوصيتكم'.tr(),
                content: 'شركة ار زو تلتزم بحماية خصوصية بيانات التشغيل وادراةالطلبات.'.tr(),
              ),
              
              _buildPolicySection(
                icon: Icons.data_usage,
                title: 'جمع البيانات'.tr(),
                content: 'التطبيق مصمم خصيصًا لإدارة التشغيل معمل شركة ار زو. البيانات التي نجمعها تشمل معلومات الطلبات وكميات الأصناف والمواد الخام اللازمة لإدارة التشغيل.'.tr(),
              ),
              
              _buildPolicySection(
                icon: Icons.share,
                title: 'مشاركة البيانات'.tr(),
                content: 'يتم إرسال بيانات الطلبات وكميات الأصناف فقط إلى سيرفرات شركة ار زو لتحديث التشغيل المركزي للمعمل. لا نقوم بمشاركة أي بيانات مع أطراف ثالثة.'.tr(),
              ),
              
              _buildPolicySection(
                icon: Icons.storage,
                title: 'التخزين والأمان'.tr(),
                content: 'بيانات التشغيل تُخزن بشكل آمن على سيرفرات شركة ار زو مع تطبيق أعلى معايير الأمان لحماية.'.tr(),
              ),
              
              _buildPolicySection(
                icon: Icons.phone_iphone,
                title: 'البيانات المحلية'.tr(),
                content: 'لا يوجد تخزين لاي بيانات شخصية .'.tr(),
              ),
              
              _buildPolicySection(
                icon: Icons.pause_circle_outline_sharp,
                title: 'الغرض من التطبيق'.tr(),
                content: 'هذا التطبيق مخصص لاستخدام شركة ار زو فقط لإدارة الطلبات والتشغيل الداخلي، ولا يتم استخدام البيانات لأي أغراض أخرى.'.tr(),
              ),
              
              _buildPolicySection(
                icon: Icons.verified_user,
                title: 'موافقة المستخدم'.tr(),
                content: 'باستخدامك للتطبيق، فإنك توافق على جمع بيانات التشغيل وإرسالها إلى سيرفرات شركة ار زو لأغراض إدارة الطلبات وتحديث الكميات.'.tr(),
              ),
              
              const SizedBox(height: 24),
              
              // Company Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.business, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'معلومات الشركة'.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem('الشركة:'.tr(),"آر زو".tr()),
                    _buildInfoItem('الغرض:'.tr(), 'إدارة التشغيل وطلبات المعمل'.tr()),
                    _buildInfoItem('نوع البيانات:'.tr(), 'كميات الأصناف والمواد والطلبات'.tr()),
                    _buildInfoItem('التخزين:'.tr(), 'سيرفرات شركة ار زو'.tr()),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Contact Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.contact_support, color: accentColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'معلومات التواصل'.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildContactItem(Icons.email,'البريد الإلكتروني:'.tr(),'techsaladfactory@gmail.com'),
                    _buildContactItem( Icons.phone ,"رقم الهاتف".tr() +":",'0564424765'),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Footer Note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'شركة ار زو ملتزمة بحماية بيانات التشغيل معملك وتوفير نظام آمن لإدارة الطلبات'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: secondaryColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(text: "  "),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon ,String name,String value) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 8),
        Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}