import 'package:flutter/material.dart';
import 'package:saladafactory/features/product/presentation/view/widget/productBodyView.dart';

class Productview extends StatelessWidget {
  String productName;
  double quantity;
  String unit;
  String unitId;
  String supplierName;
  String date;
  String productmain;
  bool isin;
  String expireddate;

  Productview(
      {required this.productName,
      required this.quantity,
      required this.unit,
      required this.supplierName,
      required this.isin,
      required this.unitId,
      required this.date,
      required this.productmain,
      required this.expireddate});
  @override
  Widget build(BuildContext context) {
    return ProductBodyView(
      productName: productName,
      quantity: () {
        double q = quantity ?? 0;
        return (q * 100).floorToDouble() / 100;
      }(),
      unit: unit,
      supplierName: supplierName,
      isin: isin,
      date: date,
      unitId: unit,
      productmain: productmain,
      expireddate: expireddate,
    );
  }
}
