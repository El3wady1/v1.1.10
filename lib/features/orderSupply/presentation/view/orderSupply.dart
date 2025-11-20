import 'package:flutter/material.dart';
import 'package:saladafactory/features/orderSupply/presentation/view/widget/orderSupplyBody.dart';

class orderSupply extends StatelessWidget {
var canedit;
var usercanedite;
orderSupply({required this.canedit,required this.usercanedite});
  @override
  Widget build(BuildContext context) {
    return OrderSupplyBody(canedit: canedit, usercanedite: usercanedite,);
  }
}