import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:saladafactory/features/login/presentation/view/widget/settingstartView.dart';
import 'package:saladafactory/main.dart' hide BiometricController;

class ActiveBasma extends StatelessWidget {
  const ActiveBasma({super.key});

  Widget _buildAuthStatusWidget() {
    return ValueListenableBuilder<bool>(
      valueListenable: BiometricController.instance.authNotifier,
      builder: (context, isAuthenticated, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: BiometricController.instance.enabled,
          builder: (context, enabled, _) {
            if (!enabled) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4EF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCDBCA2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFF74826A)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'البصمة معطلة - يمكن الوصول للتطبيق مباشرة'.tr(),
                        style: TextStyle(
                          color: const Color(0xFF74826A),
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
                color: isAuthenticated
                    ? const Color(0xFFF3F4EF)
                    : const Color(0xFFF3F4EF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAuthenticated
                      ? const Color(0xFF74826A)
                      : const Color(0xFFEDBE2C),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAuthenticated ? Icons.verified : Icons.pending,
                    color: isAuthenticated
                        ? const Color(0xFF74826A)
                        : const Color(0xFFEDBE2C),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuthenticated
                              ? 'مصادق بنجاح'.tr()
                              : 'في انتظار المصادقة'.tr(),
                          style: TextStyle(
                            color: isAuthenticated
                                ? const Color(0xFF74826A)
                                : const Color(0xFFEDBE2C),
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
                            color: isAuthenticated
                                ? const Color(0xFF74826A)
                                : const Color(0xFFEDBE2C),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF74826A),
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: BiometricController.instance.enabled,
            builder: (context, enabled, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: Text(
                         'إعدادات البصمة'.tr(),
                         style: TextStyle(
                           fontWeight: FontWeight.bold,
                           color: const Color(0xFF74826A),
                         ),
                       ),
             ),
            // محتوى التطبيق الرئيسي
            // Expanded(
            //   child: Animated_SplashView(),
            // ),

            // قسم البصمة في الأسفل
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4EF),
                border: Border.all(color: const Color(0xFFCDBCA2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // سويتش البصمة
                  const BiometricSwitch(
                    title: 'تفعيل البصمة',
                    subtitle:
                        'استخدام البصمة لتأمين التطبيق عند الخروج والدخول',
                  ),

                  const SizedBox(height: 10),

                  // عرض حالة المصادقة الحالية
                  _buildAuthStatusWidget(),

                  const SizedBox(height: 10),

                  // زر إضافي لتعطيل البصمة يدوياً
                  ValueListenableBuilder<bool>(
                    valueListenable: BiometricController.instance.enabled,
                    builder: (context, enabled, _) {
                      if (enabled) {
                        return Container();
                      }
                      return ElevatedButton(
                        onPressed: () {
                          BiometricController.instance.setEnabled(true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم تفعيل البصمة'.tr()),
                              backgroundColor: const Color(0xFF74826A),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF74826A),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text('تفعيل البصمة الآن'.tr()),
                      );
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

