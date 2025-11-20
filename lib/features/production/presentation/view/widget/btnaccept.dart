import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Btnaccept extends StatelessWidget {
  
  var ontap;

   Btnaccept({required this.ontap});
  final Color primaryColor = Color(0xFF2E5E3A); // Darker green
  final Color accentColor = Color(0xFFE6B905); // Brighter yellow
  final Color secondaryColor = Color(0xFF8B9E7E); // Muted green
  final Color backgroundColor = Color(0xFFF8F8F8); // Light gray background
  final Color textColor = Color(0xFF333333); // Dark gray for text
  final Color lightTextColor = Color(0xFF666666); // Lighter gray for secondary text

  @override
  Widget build(BuildContext context) {
    return     ElevatedButton(
      onPressed:ontap,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      textStyle:  GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        elevation: 4,
      ),
      child: const Text(
        'اعتماد',
        textDirection: TextDirection.rtl,
      ),
    )
         ;
  }
}