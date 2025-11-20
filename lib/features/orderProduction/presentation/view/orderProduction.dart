import 'package:flutter/material.dart';
import 'package:saladafactory/features/orderProduction/presentation/view/widget/orderProductionBody.dart';

class Orderproduction extends StatelessWidget {
var canedit;
var usercanedite;
Orderproduction({required this.canedit,required this.usercanedite});
  @override
  Widget build(BuildContext context) {
    return OrderProductionBody(canedit: canedit, usercanedite: usercanedite,);
  }
}