import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {

  String text;
  var ontap;
  double width;
  Color back_color;

  CustomButton({
    required this.back_color,
    required this.text,required this.ontap,required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: back_color,
      child: MaterialButton(
        minWidth: width,
          child: Text(text,style: TextStyle(fontSize: 25,color: Colors.white,fontWeight: FontWeight.bold),),
          onPressed: ontap,),
    );
  }
}
