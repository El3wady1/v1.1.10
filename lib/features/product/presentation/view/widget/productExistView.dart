import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as intl;
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:saladafactory/features/in/data/services/addQtyAndExpiredProductServices.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MultiBarcodeEntryView extends StatefulWidget {
  @override
  _MultiBarcodeEntryViewState createState() => _MultiBarcodeEntryViewState();
}

class _MultiBarcodeEntryViewState extends State<MultiBarcodeEntryView> {
  final Color primaryColor = const Color(0xFF74826A);
  final Color accentColor = const Color(0xFFEDBE2C);
  final Color secondaryColor = const Color(0xFFCDBCA2);
  final Color backgroundColor = const Color(0xFFF3F4EF);
  bool isloading = false;

  final List<ProductEntry> products = [];
  final TextEditingController barcodeController = TextEditingController();
  
  // New variables for supplier selection
  List<Map<String, dynamic>> suppliers = [];
  String? selectedSupplierId;
  String? selectedSupplierName;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  @override
  void dispose() {
    barcodeController.dispose();
    super.dispose();
  }

  // Fetch suppliers from API
  Future<void> _fetchSuppliers() async {
    setState(() => isloading = true);
    try {
      final response = await http.get(
        Uri.parse('${Apiendpoints.baseUrl}supplier/getAll'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['data'] != null) {
          setState(() {
            suppliers = List<Map<String, dynamic>>.from(data['data']);
            if (suppliers.isNotEmpty) {
              selectedSupplierId = suppliers[0]['_id'];
              selectedSupplierName = suppliers[0]['name'];
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل في جلب بيانات الموردين')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الخادم: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() => isloading = false);
    }
  }

  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        barcodeController.text = result.rawContent;
        _fetchProductInfo(result.rawContent);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء المسح: ${e.toString()}')),
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchProductInfo(String barcode) async {
    setState(() => isloading = true);
    try {
      final response = await http.post(
        Uri.parse('${Apiendpoints.baseUrl}product/barcode'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'bracode': barcode}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['data'] != null) {
          _showProductDialog(data['data']);
          return data['data'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('المنتج غير موجود')),
          );
          return null;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الخادم: ${response.statusCode}')),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
      return null;
    } finally {
      setState(() => isloading = false);
    }
  }

  Future<void> _showProductDialog(Map<String, dynamic> productData) async {
    final quantityController = TextEditingController(text: "1");
    final expireDateController = TextEditingController();
    final priceController =
        TextEditingController(text: productData['price'].toString());
    final noteController = TextEditingController();

    bool addProduct = false;
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: intl.TextDirection.rtl,
            child: AlertDialog(
              title: Text('معلومات المنتج'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الاسم: ${productData['name']}'),
                    SizedBox(height: 8),
                    Text('الباركود: ${productData['bracode']}'),
                    SizedBox(height: 8),
                    Text('الوحدة: ${productData['unit']['name']}'),
                    SizedBox(height: 8),
                    Text(
                        'الكمية: ${productData['availableQuantity'] ?? 'غير محدد'}'),
                    SizedBox(height: 16),
                    Text('الحجم: ${productData['packSize'] ?? 'غير محدد'}'),
                    SizedBox(height: 16),

                    // كمية
                    Text('الكمية:'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            var currentQty =
                                double.tryParse(quantityController.text) ?? 1;
                            if (currentQty > 1) {
                              setState(() {
                                quantityController.text =
                                    (currentQty - 1).toString();
                              });
                            }
                          },
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            controller: quantityController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            var currentQty =
                                double.tryParse(quantityController.text) ?? 1;
                            setState(() {
                              quantityController.text =
                                  (currentQty + 1).toString();
                            });
                          },
                        ),
                      ],
                    ),

                    // سعر
                    SizedBox(height: 10),
                    Text('السعر:'),
                    TextField(
                      controller: priceController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'أدخل السعر',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    // تاريخ الانتهاء
                    SizedBox(height: 10),
                    Text('تاريخ الانتهاء:'),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            expireDateController.text =
                                "${picked.day}/${picked.month}/${picked.year}";
                          });
                        }
                      },
                      child: IgnorePointer(
                        child: TextField(
                          controller: expireDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'اختر تاريخ الانتهاء',
                            suffixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),

                    // ملاحظات
                    SizedBox(height: 10),
                    Text('ملاحظات:'),
                    TextField(
                      maxLines: 4,
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: 'أدخل ملاحظات (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (expireDateController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('الرجاء اختيار تاريخ الانتهاء')),
                      );
                      return;
                    }

                    if (priceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('الرجاء إدخال السعر')),
                      );
                      return;
                    }

                    addProduct = true;
                    Navigator.pop(context);
                  },
                  child: Text('إضافة'),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (addProduct) {
      setState(() {
        products.add(ProductEntry(
          barcode: productData['bracode'],
          productID: productData['_id'],
          productName: productData['name'],
          unitId: productData['unit']['_id'],
          unit: productData['unit']['name'],
          supplierName: selectedSupplierName ?? productData['supplierAccepted']['name'],
          supplierId: selectedSupplierId ?? productData['supplierAccepted']['_id'],
          quantityController: quantityController,
          expireDateController: expireDateController,
          priceController: priceController,
          noteController: noteController,
          quantity: double.tryParse(quantityController.text) ?? 1,
          expireDate: selectedDate,
          packSize: productData['packSize'],
        ));
        barcodeController.clear();
      });
    }
  }

  void _removeProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
  }

  Future<void> _addExistingsaladafactory(ProductEntry product) async {
    try {
      final response = await http.post(
        Uri.parse('${Apiendpoints.baseUrl+Apiendpoints.transaction.add}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "productID": product.productID,
          "type": "INEXIST",
          "quantity": product.quantity,
          "price": double.parse(product.priceController.text),
          "expiredDate": product.expireDate!.toUtc().toIso8601String(),
          "userID": await Localls.getUserID(),
          "supplier": product.supplierId,
          "note": product.noteController.text.isNotEmpty
              ? product.noteController.text
              : "اضافه موجوده",
        }),
      );

      if (response.statusCode == 200||response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['message'] != "INEXIST transaction created successfully") {
          throw Exception(
              data['message'] ?? 'Failed to add existing saladafactory');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add existing saladafactory: $e');
    }
  }

  Future<void> _saveAllProducts() async {
    setState(() => isloading = true);

    // Validate all products
    for (var product in products) {
      if (product.expireDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('الرجاء اختيار تاريخ الانتهاء لكل المنتجات')),
        );
        setState(() => isloading = false);
        return;
      }

      if (product.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال كمية صحيحة لكل المنتجات')),
        );
        setState(() => isloading = false);
        return;
      }

      final price = double.tryParse(product.priceController.text);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال سعر صحيح لكل المنتجات')),
        );
        setState(() => isloading = false);
        return;
      }
    }

    try {
      for (var product in products) {
        await _addExistingsaladafactory(product);

        String isoExpireDate = product.expireDate!.toUtc().toIso8601String();

        await addQuantityAndExpiryDate(
          qty: product.quantity,
          bracode: product.barcode,
          expireDate: isoExpireDate,
          priceIN: double.parse(product.priceController.text),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة جميع المنتجات بنجاح'.tr())),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() => isloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      color: Colors.black,
      opacity: 0.6,
      inAsyncCall: isloading,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('إدخال متعدد للباركود'),
          backgroundColor: primaryColor,
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveAllProducts,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Supplier selection dropdown
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedSupplierId,
                    hint: Text('اختر المورد'),
                    underline: SizedBox(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedSupplierId = newValue;
                        selectedSupplierName = suppliers.firstWhere(
                          (supplier) => supplier['_id'] == newValue)['name'];
                        
                        // Update supplier for all existing products
                        for (var product in products) {
                          product.supplierId = newValue!;
                          product.supplierName = selectedSupplierName!;
                        }
                      });
                    },
                    items: suppliers.map<DropdownMenuItem<String>>((supplier) {
                      return DropdownMenuItem<String>(
                        value: supplier['_id'],
                        child: Text(supplier['name']),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Barcode input section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeController,
                        decoration: InputDecoration(
                          labelText: 'مسح الباركود',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.qr_code_scanner),
                            onPressed: _scanBarcode,
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _fetchProductInfo(value);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (barcodeController.text.isNotEmpty) {
                          _fetchProductInfo(barcodeController.text);
                        }
                      },
                      child: Text('إضافة'),
                    ),
                  ],
                ),
              ),

              // List of products
              if (products.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'لا توجد منتجات مضافة. قم بمسح الباركود لإضافة منتج جديد.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.productName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'الباركود: ${product.barcode}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      if (product.packSize != null)
                                        Text(
                                          'الحجم: ${product.packSize}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeProduct(index),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                    'الكمية: ${product.quantity.toStringAsFixed(product.quantity % 1 == 0 ? 0 : 2)}'),
                                SizedBox(width: 20),
                                Text('السعر: ${product.priceController.text}'),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                                'تاريخ الانتهاء: ${product.expireDateController.text}'),
                            SizedBox(height: 10),
                            // Text('المورد: ${product.supplierName}'),
                            Text('الوحدة: ${product.unit}'),
                            if (product.noteController.text.isNotEmpty)
                              Text('ملاحظات: ${product.noteController.text}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductEntry {
  final String barcode;
  final String productID;
  final String productName;
  final String unitId;
  final String unit;
  String supplierName;
  String supplierId;
  final String? packSize;
  double quantity;
  DateTime? expireDate;
  TextEditingController quantityController;
  TextEditingController expireDateController;
  TextEditingController priceController;
  TextEditingController noteController;

  ProductEntry({
    required this.barcode,
    required this.productID,
    required this.productName,
    required this.unitId,
    required this.unit,
    required this.supplierName,
    required this.supplierId,
    required this.quantityController,
    required this.expireDateController,
    required this.priceController,
    required this.noteController,
    required this.quantity,
    this.expireDate,
    this.packSize,
  });
}