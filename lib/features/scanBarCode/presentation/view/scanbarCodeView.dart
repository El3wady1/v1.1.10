import 'package:flutter/material.dart';
import 'package:saladafactory/features/scanBarCode/presentation/view/widget/scanbarCodeINBodyView.dart';

class ScanbarcodeInview extends StatelessWidget {
var mainProduct;
ScanbarcodeInview({required this.mainProduct});
  @override
  Widget build(BuildContext context) {
    return  ScanbarcodeINbodyview(mainProduct);
  }
}