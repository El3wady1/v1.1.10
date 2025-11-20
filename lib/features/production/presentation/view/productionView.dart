import 'package:flutter/material.dart';
import 'package:saladafactory/features/production/presentation/view/widget/productionBodyView.dart';

class Productionview extends StatelessWidget {

  var role;
   Productionview({required this.role});

  @override
  Widget build(BuildContext context) {
    return ProductionBodyView(role: role,);
  }
}