import 'package:flutter/material.dart';

class Custom_Textfeild extends StatelessWidget {
  Widget suffixIcon;

  Widget prefixIcon;
  double h;
  String hint;
  Color backgroundcolor;
  Color bordercolor;
  TextStyle hintstyle;
  double borderwidth;
  var validate;
  var line;
  TextStyle labelStyle;
  TextInputType keyboardtype;

  //
  var controller;

  bool obscuretext;

  Custom_Textfeild(

      {
        required this.h,

        @required this.line,
      required this.obscuretext,
      required this.controller,
      required this.labelStyle,
      required this.validate,
      required this.keyboardtype,
      required this.prefixIcon,
      required this.suffixIcon,
      required this.hint,
      required this.backgroundcolor,
      required this.bordercolor,
      required this.hintstyle,
      required this.borderwidth,
      required this.borderradius, required int maxlines});

  double borderradius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        height: h,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
          borderRadius: BorderRadius.circular(borderradius),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: obscuretext,
          keyboardType: keyboardtype,
          textInputAction: TextInputAction.next,
          validator: validate,
          decoration: InputDecoration(
            filled: true,
            fillColor: backgroundcolor,
            suffix: suffixIcon,
            prefix: prefixIcon,
            labelStyle: labelStyle,
            hintStyle: hintstyle,
            hintText: hint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderradius),
                borderSide: BorderSide(width: borderwidth, color: bordercolor)),
          ),
        ),
      ),
    );
  }
}
