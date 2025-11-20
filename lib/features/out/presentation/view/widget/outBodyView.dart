import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/app_router.dart';
import 'dart:convert';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../../../home/presentation/view/widget/succesView.dart';

class Outbodyview extends StatefulWidget {
  @override
  _BulkOutViewState createState() => _BulkOutViewState();
}

class _BulkOutViewState extends State<Outbodyview> {
  static Color primaryColor = Color(0xFF74826A);
  static Color accentColor = Color(0xFFEDBE2C);
  static Color secondaryColor = Color(0xFFCDBCA2);
  static Color backgroundColor = Color(0xFFF3F4EF);
  static Color errorColor = Color(0xFFD32F2F);

  List<OutItem> items = [];
  List<Map<String, dynamic>> suppliers = [];
  bool isLoading = false;
  bool isScanning = false;
  bool isFetchingSuppliers = false;
  MobileScannerController cameraController = MobileScannerController();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  String? lastScannedBarcode;
  DateTime? lastScanTime;
  final Duration scanCooldown = Duration(seconds: 2);
  int scanAttempts = 0;
  final int maxScanAttempts = 3;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openBarcodeScanner());
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void showCustomSnackBar({
    required String message,
    required IconData icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? errorColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  Future<void> _fetchSuppliers() async {
    if (!mounted) return;
    setState(() => isFetchingSuppliers = true);

    try {
      final url = Uri.parse(
        Apiendpoints.baseUrl + Apiendpoints.supplier.getall,
      );
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData["status"] == 200) {
          setState(() {
            suppliers = List<Map<String, dynamic>>.from(responseData["data"]);
          });
        } else {
          showCustomSnackBar(
            message: responseData["message"] ?? "فشل في جلب الموردين",
            icon: Icons.error,
          );
        }
      } else {
        showCustomSnackBar(
          message: "خطأ في الخادم: ${response.statusCode}",
          icon: Icons.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      print("Error fetching suppliers: $e");
      showCustomSnackBar(
        message: "حدث خطأ أثناء جلب الموردين",
        icon: Icons.error,
      );
    } finally {
      if (mounted) {
        setState(() => isFetchingSuppliers = false);
      }
    }
  }

  Future<void> subtractProductQuantity(
      {required String barcode, required double quantityToSubtract}) async {
    try {
      final url =
          Uri.parse(Apiendpoints.baseUrl + Apiendpoints.product.outproduct);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "bracode": barcode,
          "quantityToSubtract": quantityToSubtract,
        }),
      );

      if (!mounted) return;

      if (response.statusCode != 200 && response.statusCode != 201) {
        print("Failed to subtract quantity: ${response.body}");
        throw Exception("Failed to subtract quantity");
      }
    } catch (e) {
      print("Error subtracting quantity: $e");
      throw e;
    }
  }

  void _openBarcodeScanner() async {
    if (!mounted || isScanning) return;
    setState(() {
      isScanning = true;
      scanAttempts = 0; // Reset scan attempts when opening scanner
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => SafeArea(
        child: Scaffold(
          floatingActionButton: Padding(
            padding: EdgeInsets.all(8.0),
            child: ElevatedButton(
              child: Text(
                "التالي",
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.w800),
              ),
              onPressed: () {
                Navigator.pop(context);
                _navigateToReviewPage();
              },
            ),
          ),
          appBar: AppBar(
            title: Text("مسح الباركود"),
            centerTitle: true,
            backgroundColor: primaryColor,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: cameraController,
                  builder: (context, state, child) {
                    return Icon(
                      state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    );
                  },
                ),
                onPressed: () => cameraController.toggleTorch(),
              ),
            ],
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: cameraController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _handleBarcodeScan(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.width * 0.7,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: accentColor,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      textAlign: TextAlign.center,
                      "وجه الباركود في المريع بعد الانتهاء\n من مسح جميع الباركودات اضغط التالي ",
                      style: GoogleFonts.cairo(
                        color: Colors.red.shade900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() => isScanning = false);
      }
    });
  }

  void _navigateToReviewPage() {
    if (items.isEmpty) {
      showCustomSnackBar(
        message: "لم يتم إضافة أي عناصر للمراجعة",
        icon: Icons.warning,
        backgroundColor: accentColor,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewOutItemsPage(
          items: items,
          suppliers: suppliers,
          onSubmit: _submitAllTransactions,
        ),
      ),
    ).then((_) {
      // إعادة فتح الماسح الضوئي بعد العودة من صفحة المراجعة
      if (mounted) {
                  Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SuccessPage()),
    );      }
    });
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    if (!mounted) return;
    if (barcode.isEmpty) return;

    final now = DateTime.now();
    if (lastScannedBarcode == barcode &&
        lastScanTime != null &&
        now.difference(lastScanTime!) < scanCooldown) {
      return;
    }

    lastScannedBarcode = barcode;
    lastScanTime = now;

    // Check if we've exceeded max scan attempts
    scanAttempts++;
    if (scanAttempts > maxScanAttempts) {
      showCustomSnackBar(
        message:
            "تم تجاوز الحد الأقصى لمحاولات المسح. يرجى المحاولة مرة أخرى لاحقًا.",
        icon: Icons.error,
        duration: Duration(seconds: 5),
      );
      return;
    }

    final existingItemIndex =
        items.indexWhere((item) => item.barcode == barcode);
    if (existingItemIndex != -1) {
      final existingItem = items[existingItemIndex];
      showCustomSnackBar(
        message: "هذا المنتج مضاف مسبقاً (${existingItem.name})",
        icon: Icons.warning,
        backgroundColor: accentColor,
      );

      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("تحديث الكمية"),
          content: Text(
              "المنتج ${existingItem.name} مضاف مسبقاً. هل تريد تحديث كميته؟"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("لا"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("نعم"),
            ),
          ],
        ),
      );

      if (shouldUpdate == true) {
        final newQuantity = await showDialog<double>(
          context: context,
          barrierDismissible: false,
          builder: (context) => QuantityInputDialog(
            productName: existingItem.name,
            availableQuantity: existingItem.availableQuantity,
            unit: existingItem.unit,
            initialQuantity: existingItem.quantity,
          ),
        );

        if (newQuantity != null && newQuantity > 0) {
          setState(() {
            items[existingItemIndex].quantity = newQuantity;
          });
        }
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
        Apiendpoints.baseUrl + Apiendpoints.product.getByBarcode,
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "bracode": barcode,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData["status"] == 200) {
          final productData = responseData["data"];

          final quantity = await showDialog<double>(
            context: context,
            barrierDismissible: false,
            builder: (context) => QuantityInputDialog(
              productName: productData['name'] ?? 'غير معروف',
              availableQuantity: double.tryParse(
                      productData['availableQuantity']?.toString() ?? '0') ??
                  0,
              unit: productData['unit']?['name'] ?? 'وحدة',
            ),
          );

          if (quantity != null && quantity > 0) {
            setState(() {
              items.add(OutItem(
                barcode: barcode,
                name: productData['name'] ?? 'غير معروف',
                productId: productData['_id']?.toString(),
                availableQuantity: double.tryParse(
                        productData['availableQuantity']?.toString() ?? '0') ??
                    0,
                unit: productData['unit']?['name'] ?? 'وحدة',
                unitId: productData['unit']?['_id']?.toString(),
                supplier:
                    productData['supplierAccepted']?['name'] ?? 'غير معروف',
                departments: productData['departments'] ?? [],
                updatedAt: productData['updatedAt'] ?? 'غير معروف',
                mainProduct: productData['mainProduct']?['name'] ?? 'غير معروف',
                expiryDate: productData['updated']?.isNotEmpty == true
                    ? productData['updated'][0]['expireDate']
                    : 'غير معروف',
                quantity: quantity,
              ));
              scanAttempts = 0; // Reset on successful scan
            });
          }
        } else {
          showCustomSnackBar(
            message: responseData["message"] ?? "المنتج غير موجود",
            icon: Icons.error,
          );
        }
      } else if (response.statusCode == 404) {
        showCustomSnackBar(
          message: "المنتج غير موجود",
          icon: Icons.error,
        );
      } else {
        showCustomSnackBar(
          message: "خطأ في الخادم: ${response.statusCode}",
          icon: Icons.error,
        );
        print("Error:${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      print("Error: $e");
      showCustomSnackBar(
        message: "حدث خطأ أثناء جلب بيانات المنتج",
        icon: Icons.error,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // دالة مساعدة للحصول على معرف المورد
  String getSupplierId(String? supplierName) {
    if (supplierName == null) return '';
    
    final supplier = suppliers.firstWhere(
      (sup) => sup['name'] == supplierName,
      orElse: () => Map<String, dynamic>(),
    );
    
    return supplier['_id']?.toString() ?? '';
  }

  Future<bool> makeOUTTransaction({
    required String productID,
    required String type,
    required double quantity,
    required String userID,
    required String unit,
    required String department,
    required String supplierId,
    required String barcode,
  }) async {
    try {
      final url =
          Uri.parse(Apiendpoints.baseUrl + Apiendpoints.transaction.add);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "productID": productID,
          "type": "OUT",
          "quantity": quantity,
          "userID": userID,
          "supplier": supplierId,
          "note": "تم اخراج كميه : $quantity"
        }),
      );

      if (!mounted) return false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData["message"] == "Transaction created successfully") {
          await subtractProductQuantity(
              barcode: barcode, quantityToSubtract: quantity);

          return true;
        } else {
          print("Transaction failed: ${responseData["message"]}");
          return false;
        }
      } else {
        print("Server error: ${response.statusCode}, ${response.body}");
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      print("Error in makeOUTTransaction: $e");
      return false;
    }
  }

  Future<void> _submitAllTransactions(
      List<OutItem> itemsToSubmit, String selectedSupplier) async {
    if (!mounted) return;

    final userId = await Localls.getUserID();
    final department = await Localls.getdepartment();

    if (userId == null || department == null) {
      showCustomSnackBar(
        message: "يجب تسجيل الدخول أولاً وتحديد القسم",
        icon: Icons.error,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      List<String> successItems = [];
      List<String> failedItems = [];

      for (var item in itemsToSubmit) {
        try {
          if (!mounted) break;

          // الحصول على معرف المورد
          String supplierId = getSupplierId(selectedSupplier);

          bool success = await makeOUTTransaction(
            productID: item.productId.toString(),
            type: "OUT",
            quantity: item.quantity,
            userID: userId,
            unit: item.unitId.toString(),
            department: department,
            supplierId: supplierId,
            barcode: item.barcode,
          );

          if (success) {
            successItems.add(item.name);
          } else {
            failedItems.add(item.name);
          }
        } catch (e) {
          if (!mounted) break;
          print("Error processing item ${item.name}: $e");
          failedItems.add(item.name);
        }
      }

      if (!mounted) return;

      if (failedItems.isEmpty) {
        // إزالة العناصر التي تمت معالجتها بنجاح
        setState(() {
          items.removeWhere((item) => 
            successItems.contains(item.name));
        });
        
        showCustomSnackBar(
          message: "تم إرسال جميع العمليات بنجاح (${successItems.length})",
          icon: Icons.check_circle,
          backgroundColor: Colors.green,
        );
        
        // العودة إلى الصفحة الرئيسية بعد النجاح
        Navigator.popUntil(context, (route) => route.isFirst);
      } else if (successItems.isNotEmpty) {
        // إزالة العناصر الناجحة فقط
        setState(() {
          items.removeWhere((item) => successItems.contains(item.name));
        });
        
        showCustomSnackBar(
          message:
              "تم إرسال ${successItems.length} عملية بنجاح وفشل ${failedItems.length}",
          icon: Icons.warning,
          backgroundColor: accentColor,
        );
        
        // تحديث صفحة المراجعة مع العناصر المتبقية
        Navigator.pop(context);
      } else {
        showCustomSnackBar(
          message: "فشل في إرسال جميع العمليات",
          icon: Icons.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      print("Error submitting transactions: $e");
      showCustomSnackBar(
        message: "حدث خطأ أثناء إرسال العمليات",
        icon: Icons.error,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text("إخراج المنتجات"),
            backgroundColor: primaryColor,
            centerTitle: true,
          ),
          body: ModalProgressHUD(
            inAsyncCall: isLoading,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: primaryColor,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'انقر لبدء المسح',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _openBarcodeScanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text(
                      'فتح الماسح الضوئي',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (items.isNotEmpty)
                    Text(
                      'عدد العناصر المضافة: ${items.length}',
                      style: TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReviewOutItemsPage extends StatefulWidget {
  final List<OutItem> items;
  final List<Map<String, dynamic>> suppliers;
  final Function(List<OutItem>, String) onSubmit;

  ReviewOutItemsPage({
    required this.items,
    required this.suppliers,
    required this.onSubmit,
  });

  @override
  _ReviewOutItemsPageState createState() => _ReviewOutItemsPageState();
}

class _ReviewOutItemsPageState extends State<ReviewOutItemsPage> {
  String? selectedSupplier;
  bool isLoading = false;
  List<TextEditingController> quantityControllers = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each item
    quantityControllers = widget.items
        .map((item) =>
            TextEditingController(text: item.quantity.toStringAsFixed(2)))
        .toList();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text("مراجعة العناصر (${widget.items.length})"),
            centerTitle: true,
            backgroundColor: _BulkOutViewState.primaryColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text("المورد",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _BulkOutViewState.primaryColor,
                            )),
                        SizedBox(height: 15),
                        AcceptedDropBox(
                          items: widget.suppliers.isNotEmpty
                              ? widget.suppliers
                                  .map<String>((sup) => sup['name'].toString())
                                  .toList()
                              : ["لا يوجد موردين"],
                          label: "اختر المورد",
                          icon: Icons.business,
                          onChanged: (value) =>
                              setState(() => selectedSupplier = value),
                          value: selectedSupplier,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: 80),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final controller = quantityControllers[index];

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.29,
                                        child: Text(
                                          maxLines: 2,
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _BulkOutViewState.primaryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(" - "),
                                      Expanded(
                                        child: Text(
                                          item.mainProduct,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _BulkOutViewState.primaryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "م : ${item.quantity.toStringAsFixed(2)} ${item.unit}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _BulkOutViewState.primaryColor
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              "الباركود: ${item.barcode}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Divider(
                              height: 24,
                              thickness: 1,
                              color: _BulkOutViewState.secondaryColor,
                            ),
                            Row(
                              children: [
                                Text(
                                  "الكمية: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _BulkOutViewState.primaryColor,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  width: 100,
                                  child: TextField(
                                    controller: controller,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                    ),
                                    onChanged: (value) {
                                      final newValue =
                                          double.tryParse(value) ?? 0.0;
                                      if (newValue > 0 &&
                                          newValue <= item.availableQuantity) {
                                        setState(() {
                                          item.quantity = newValue;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  item.unit,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              "الكمية المتاحة: ${item.availableQuantity.toStringAsFixed(2)} ${item.unit}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              if (selectedSupplier == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("يجب تحديد المورد"),
                    backgroundColor: _BulkOutViewState.errorColor,
                  ),
                );
                return;
              }

              showDialog(
                context: context,
                builder: (context) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: Text(textAlign: TextAlign.center, "تأكيد الإرسال"),
                    content: Text(
                        "هل أنت متأكد من إرسال ${widget.items.length} عنصر إلى $selectedSupplier؟"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("إلغاء"),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          setState(() => isLoading = true);
                          await widget.onSubmit(widget.items, selectedSupplier!);
                          setState(() => isLoading = false);
        
                        },
                        child: Text("تأكيد"),
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white))
                : Icon(Icons.send, color: Colors.white),
            label: Text(isLoading ? "جاري الإرسال..." : "إرسال الكل",
                style: TextStyle(color: Colors.white)),
            backgroundColor: _BulkOutViewState.primaryColor,
            elevation: 4,
          ),
        ),
      ),
    );
  }
}

class QuantityInputDialog extends StatefulWidget {
  final String productName;
  final double availableQuantity;
  final String unit;
  final double? initialQuantity;

  QuantityInputDialog({
    required this.productName,
    required this.availableQuantity,
    required this.unit,
    this.initialQuantity,
  });

  @override
  _QuantityInputDialogState createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<QuantityInputDialog> {
  late TextEditingController _quantityController;
  double quantity = 1.0;

  @override
  void initState() {
    super.initState();
    quantity = widget.initialQuantity ?? 1.0;
    _quantityController =
        TextEditingController(text: quantity.toStringAsFixed(2));
    _quantityController.addListener(_validateQuantity);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _validateQuantity() {
    final value = double.tryParse(_quantityController.text) ?? 0.0;
    setState(() {
      quantity = value.clamp(0.1, widget.availableQuantity);
      if (value != quantity) {
        _quantityController.text = quantity.toStringAsFixed(2);
        _quantityController.selection = TextSelection.fromPosition(
            TextPosition(offset: _quantityController.text.length));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("إدخال الكمية"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.productName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
          SizedBox(height: 8),
          Text(
              "الكمية المتاحة: ${widget.availableQuantity.toStringAsFixed(2)} ${widget.unit}"),
          SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "الكمية",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle, size: 32),
                onPressed: () {
                  if (quantity > 0.1) {
                    setState(() {
                      quantity -= 1;
                      _quantityController.text = quantity.toStringAsFixed(2);
                    });
                  }
                },
              ),
              SizedBox(width: 20),
              IconButton(
                icon: Icon(Icons.add_circle, size: 32),
                onPressed: () {
                  if (quantity < widget.availableQuantity) {
                    setState(() {
                      quantity += 1;
                      _quantityController.text = quantity.toStringAsFixed(2);
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 0.0),
          child: Text("إلغاء"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, quantity),
          child: Text("حفظ"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _BulkOutViewState.primaryColor,
          ),
        ),
      ],
    );
  }
}

class OutItem {
  final String barcode;
  final String name;
  final String? productId;
  final double availableQuantity;
  final String unit;
  final String? unitId;
  final dynamic supplier;
  final dynamic departments;
  final String updatedAt;
  final String mainProduct;
  final String expiryDate;
  double quantity;

  OutItem({
    required this.barcode,
    required this.name,
    required this.productId,
    required this.availableQuantity,
    required this.unit,
    required this.unitId,
    required this.supplier,
    required this.departments,
    required this.updatedAt,
    required this.mainProduct,
    required this.expiryDate,
    required this.quantity,
  });
}

class AcceptedDropBox extends StatelessWidget {
  final List<String> items;
  final String label;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  final String? value;

  AcceptedDropBox({
    required this.items,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _BulkOutViewState.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _BulkOutViewState.primaryColor),
        ),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يجب اختيار قيمة';
        }
        return null;
      },
    );
  }
}