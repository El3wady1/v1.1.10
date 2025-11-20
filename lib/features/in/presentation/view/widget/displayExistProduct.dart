import 'package:flutter/material.dart';
import 'package:saladafactory/features/in/data/services/getProductByBarcodeINService.dart';
import 'package:saladafactory/features/product/presentation/view/widget/productExistView.dart';

class Displayexistproduct extends StatefulWidget {
  final String barcode;
  const Displayexistproduct({required this.barcode});

  @override
  State<Displayexistproduct> createState() => _DisplayexistproductState();
}

class _DisplayexistproductState extends State<Displayexistproduct> {
  late Future<dynamic> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = getProductByBarcodeINService(
      barbracode: widget.barcode,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('لم يتم العثور على المنتج'));
        }

        final data = snapshot.data;

        if (data == null || data['data'] == null) {
          return const Center(child: Text('لم يتم العثور على المنتج'));
        }

        final product = data['data'];

        return MultiBarcodeEntryView();
        
        // ProductExistView(
        //   productName: product['name'] ?? 'غير معروف',
        //   quantity: parseToDouble(product['availableQuantity']),
        //   unitId: product['unit']?['_id'] ?? '',
        //   supplierName: product['supplierAccepted']?['name'] ?? 'غير محدد',
        //   createdAtdate: product['updatedAt'] ?? '',
        //   productID: product['_id'] ?? '',
        //   unit: product['unit']?['name'] ?? '',
        //   bracode: widget.barcode,
        //   productmain: product["mainProduct"]['name'] ?? '',
        //   expireddate: product["updated"]?.last?["expireDate"] ?? '',
        // );
      },
    );
  }
}
