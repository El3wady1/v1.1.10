import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:saladafactory/core/Widgets/custom_text.dart';
import 'package:saladafactory/core/utils/Strings.dart';
import 'package:saladafactory/core/utils/assets.dart';
import 'package:saladafactory/core/utils/styles.dart';

class SplashBodyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF3F4EF), // اللون الفاتح #F3F4EF للأعلى
                const Color(0xFFCDBCA2), // اللون البيج #CDBCA2 للأسفل
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  AssetIcons.logo,
                  width: MediaQuery.of(context).size.width * .5,
                  //color: const Color(0xFF74826A), // لون الشعار #74826A
                ),
              ),
              const SizedBox(height: 15),
              Custom_Text(
                text: Strings.appName.tr(),
                style: TextAppStyles.cairo20.copyWith(
                  color: const Color(0xFF74826A), // لون النص #74826A
                  fontWeight: FontWeight.bold,
                ),
              ),
              Custom_Text(
                text: "${"اصدار".tr()} ${Strings.appVersion}",
                style: TextAppStyles.cairo15.copyWith(
                  color: const  Color(0xFF74826A) // لون الإصدار #EDBE2C
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}