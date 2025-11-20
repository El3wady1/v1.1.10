import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UpdatingScreen extends StatelessWidget {
  const UpdatingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4EF), // استخدام اللون البيج الفاتح كخلفية
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(30),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // دائرة تقدم مخصصة
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4EF),
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFEDBE2C)), // اللون الذهبي
                    strokeWidth: 6,
                    backgroundColor: const Color(0xFFCDBCA2).withOpacity(0.3), // اللون البيج
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // النص الرئيسي
                Text(
                  "جاري التحديث".tr(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF74826A), // اللون الأخضر الداكن
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 10),
                
                // النص الثانوي
                Text(
                  "نقوم بتحديث التطبيق للحصول على أفضل تجربة استخدام".tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // مؤشر تقدم نصي
                Text(
                  "الرجاء الانتظار...".tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF74826A).withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}