import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Cardhome extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  
  final Color primaryColor = const Color(0xFF74826A);
  final Color accentColor = const Color(0xFFEDBE2C);
  final Color secondaryColor = const Color.fromARGB(255, 211, 176, 124);
  final Color backgroundColor = const Color.fromARGB(255, 250, 250, 250);
  static const Color neutralLight = Color(0xFFCDBCA2);
  static const Color shadowColor = Color(0x4074826A);

  Cardhome({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    
    final bool isLargeScreen = width > 600;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(width * 0.02),
        constraints: BoxConstraints(
          minWidth: 0,
          maxWidth: isLargeScreen ? width * 0.15 : width * 0.3, // عرض أقل للشاشات الكبيرة
          minHeight: 0,
          maxHeight: isLargeScreen ? width * 0.15 : height * 0.2, // ارتفاع أقل للشاشات الكبيرة
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.06),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              spreadRadius: 2,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(width * 0.06),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor.withOpacity(0.9),
                      neutralLight.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: -height * 0.05,
                right: -width * 0.05,
                child: Container(
                  width: width * 0.3,
                  height: width * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.15),
                  ),
                ),
              ),

              Material(
                color: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          width: isLargeScreen ? width * 0.1 : width * 0.15,
                          height: isLargeScreen ? width * 0.1 : width * 0.15,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            size: isLargeScreen ? width * 0.05 : width * 0.07,
                          ),
                        ),
                      ),

                      if (!isLargeScreen) ...[ // إخفاء النص في الشاشات الكبيرة
                        SizedBox(height: width * 0.03),

                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.035,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        SizedBox(height: width * 0.02),
                        Container(
                          width: width * 0.08,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}