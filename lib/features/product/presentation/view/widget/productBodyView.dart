import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saladafactory/features/product/presentation/view/widget/productCard.dart';

class ProductBodyView extends StatelessWidget {
  final String productName;
  final double quantity;
  final String unitId;
  final String unit;
  final String supplierName;
  final String date;
  final String expireddate;
  bool isin;
  String productmain;
  ProductBodyView({
    required this.productName,
    required this.quantity,
    required this.unitId,
    required this.supplierName,
    required this.isin,
    required this.date,
    required this.unit,
    required this.productmain,
    required this.expireddate
  
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل الصنف',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
                    const SizedBox(height: 10),

          
           ProductCard(
            label: 'اسم الصنف الرئيسي:',
            value: productmain,
            prefixIcon: Icons.inventory,
            valueColor: Colors.black87,
          ),
           const SizedBox(height: 8),
          ProductCard(
            label: 'اسم الصنف:',
            value: productName,
            prefixIcon: Icons.inventory,
            valueColor: Colors.black87,
          ),  
          const SizedBox(height: 8),
          ProductCard(
            label: 'الكمية:',
            value: quantity.toString(),
            prefixIcon: Icons.confirmation_number,
            valueColor: Colors.deepPurple,
          ),
          const SizedBox(height: 8),
          ProductCard(
            label: 'وحدة القياس:',
            value: unitId,
            prefixIcon: Icons.straighten,
            valueColor: Colors.blueGrey,
          ),
          // const SizedBox(height: 8),
          // ProductCard(
          //   label: 'اسم المورد:',
          //   value: supplierName,
          //   prefixIcon: Icons.local_shipping,
          //   valueColor: Colors.green[700],
          // ),
          // const SizedBox(height: 8),
          // ProductCard(
          //   label: isin ? 'تاريخ اخر الادخال :' : 'تاريخ اخرج الأخراج :',
          //   value:date ,
          //   prefixIcon: Icons.date_range_outlined,
          //   valueColor: Colors.red[700],
          // ), const SizedBox(height: 12),
        //  isin? Container():ProductCard(
        //     label:  "تاريخ انتهاء االدفعه المخرجة",
        //     value:expireddate ,
        //     prefixIcon: Icons.date_range_outlined,
        //     valueColor: Colors.red[700],
        //   ),
        ],
      ),
    );
  }
}
