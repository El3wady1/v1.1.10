import 'package:flutter/material.dart';
import 'custom_text.dart';
class Custom_Button extends StatelessWidget {
  String text;
  TextStyle style;
  Color backgroundcolor;
  Color bordercolor;
  double width;
  double heigth;
  var ontap;
  double radius;
  double widthborder;

  Custom_Button({required this.text,
    required this.ontap,

    required this.style,
    required this.backgroundcolor,
    required this.width,
    required this.heigth,
    required this.radius,
    required this.bordercolor,
    required this.widthborder,

  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: heigth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: bordercolor, width:widthborder),
        color: backgroundcolor,
      ),
      child: MaterialButton(
          child: Custom_Text(
            style: style,
            text: text,
          ),
          onPressed: ontap),
    );

    ;
  }
}
