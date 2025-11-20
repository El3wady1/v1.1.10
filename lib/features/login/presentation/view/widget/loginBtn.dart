import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saladafactory/core/utils/styles.dart';

class Loginbtn extends StatelessWidget {
var ontap;
Loginbtn({required this.ontap});
  @override
  Widget build(BuildContext context) {
    return      SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: ontap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 3,
                        textStyle:  GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(
                        'تسجيل الدخول'.tr(),
                        style: TextAppStyles.cairobold12,
                      ),
                    ),
                  )
;
  }
}