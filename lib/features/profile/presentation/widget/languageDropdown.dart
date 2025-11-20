import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saladafactory/core/app_router.dart';

import '../../../splash/presentation/view/widgets/animated_splash.dart';

class LanguageDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
      value: context.locale,
      underline: SizedBox(),
      onChanged: (Locale? locale) async {
        if (locale != null) {
          await context.setLocale(locale); // تغيير اللغة
          Routting.pushreplaced(context, Animated_SplashView()); // إعادة توجيه للسـبلاش
        }
      },
      items: [
        DropdownMenuItem(
          value: Locale('ar'),
          child: Row(
            children: [
              Text("🇸🇦", style: GoogleFonts.cairo(fontSize: 10)),
              SizedBox(width: 8),
              Text("العربية", style: GoogleFonts.cairo(fontWeight: FontWeight.w800,fontSize: 10),),
            ],
          ),
        ),
        DropdownMenuItem(
          value: Locale('en'),
          child: Row(
            children: [
              Text("🇬🇧", style: GoogleFonts.cairo(fontSize: 10)),
              SizedBox(width: 8),
              Text("English", style: GoogleFonts.cairo(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}
