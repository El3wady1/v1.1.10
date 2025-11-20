import 'package:flutter/material.dart';

class Custom_Text extends StatelessWidget {
String text;
TextStyle style ;


Custom_Text({required this.text,required this.style});

  @override
  Widget build(BuildContext context) {
    return Text("$text", style:style,)

    ;
  }
}
