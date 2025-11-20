import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter/material.dart' as flutter;

class LastOrderSupplyview extends StatefulWidget {
  final String role;
  var canedite;
  var usercanedite;
  LastOrderSupplyview({required this.role, required this.canedite,required this.usercanedite});

  @override
  _LastOrderSupplyviewState createState() =>
      _LastOrderSupplyviewState();
}

class _LastOrderSupplyviewState extends State<LastOrderSupplyview> {
  List<ProductionItem> items = [];
  List<ProductionItem> filteredItems = [];
  List<AdditionalProduct> additionalProducts = [];
  List<AdditionalProduct> filteredAdditionalProducts = [];
  Map<String, TextEditingController> quantityControllers = {};
  Map<String, double> originalQuantities = {};
  Map<String, TextEditingController> additionalProductControllers = {};
  bool isLoading = false;
  bool showContent = false;
  bool showAdditionalProducts = false;
  String apiUrl = "${Apiendpoints.baseUrl}${Apiendpoints.orderSupply.getOrderSof2Days}";
  String BranchOPuser = "${Apiendpoints.baseUrl}${Apiendpoints.auth.userBranchOS}";
  String submitUrl = "${Apiendpoints.baseUrl+Apiendpoints.productionSupply.request}";
  String editUrl = "${Apiendpoints.baseUrl+Apiendpoints.orderSupply.update}";
  String addProductUrl = "${Apiendpoints.baseUrl+Apiendpoints.orderSupply.add}";
  String productsUrl = "${Apiendpoints.baseUrl}${Apiendpoints.productOP.getAll}";
  String lastOrderName = '';
  Map<String, bool> branchIsSendStatus = {};

  // Colors
  final Color primaryColor = Color(0xFF74826A);
  final Color accentColor = Color(0xFFEDBE2C);
  final Color secondaryColor = Color(0xFFCDBCA2);
  final Color backgroundColor = Color(0xFFF3F4EF);
  final Color textColor = Color(0xFF333333);
  final Color lightTextColor = Color(0xFF666666);

  List<Branch> branches = [];
  Branch? selectedBranch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBranches();
    });
  }

  @override
  void dispose() {
    quantityControllers.values.forEach((controller) => controller.dispose());
    additionalProductControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // دالة محسنة للتحقق من القيم الأقل من الصفر وأي أحرف غير رقمية
  void _validateNumericField(TextEditingController controller, {String fieldName = ''}) {
    String text = controller.text.trim();
    
    // إذا كان الحقل فارغاً، تعيين قيمة 0
    if (text.isEmpty) {
      controller.text = '0';
      _showNegativeValueWarning(fieldName);
      return;
    }

    // التحقق من أن النص يحتوي على أرقام فقط (بما في ذلك النقاط العشرية)
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      controller.text = '0';
      _showInvalidValueWarning(fieldName);
      return;
    }

    // التحقق من أن القيمة ليست أقل من الصفر
    double? value = double.tryParse(text);
    if (value == null || value < 0) {
      controller.text = '0';
      _showNegativeValueWarning(fieldName);
    }
  }

  // دالة لعرض تحذير القيم الأقل من الصفر
  void _showNegativeValueWarning(String fieldName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('لا يمكن إدخال قيم أقل من الصفر ${fieldName.isNotEmpty ? 'في $fieldName' : ''}'.tr()),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // دالة جديدة لعرض تحذير القيم غير الصالحة
  void _showInvalidValueWarning(String fieldName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('يجب إدخال أرقام فقط ${fieldName.isNotEmpty ? 'في $fieldName' : ''}'.tr()),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // دالة محسنة للتحقق من صحة القيمة المدخلة للمنتجات العادية
  void _validateAndUpdateQuantity(TextEditingController controller, ProductionItem item) {
    _validateNumericField(controller, fieldName: 'الكمية');
    
    // تحديث قيمة العنصر بعد التحقق
    String text = controller.text.trim();
    double? value = double.tryParse(text);
    if (value != null && value >= 0) {
      item.requestedQty = value;
    } else {
      item.requestedQty = 0;
      controller.text = '0';
    }
  }

  // دالة محسنة للتحقق من صحة القيمة المدخلة للمنتجات الإضافية
  void _validateAndUpdateAdditionalQuantity(TextEditingController controller, AdditionalProduct product) {
    _validateNumericField(controller, fieldName: 'الكمية');
  }

  // دالة جديدة لمنع إدخال القيم الأقل من الصفر مباشرة في الحقل
  String? _numericInputValidator(String? value) {
    if (value == null || value.isEmpty) {
      return '0';
    }
    
    // التحقق من أن القيمة تحتوي على أرقام فقط
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(value)) {
      return '0';
    }
    
    // التحقق من أن القيمة ليست أقل من الصفر
    double? numericValue = double.tryParse(value);
    if (numericValue == null || numericValue < 0) {
      return '0';
    }
    
    return null;
  }

  // دالة جديدة للتحكم في الإدخال ومنع الكتابة المباشرة للقيم السالبة
  TextInputFormatter get _positiveNumberFormatter => 
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'));

  Future<void> _loadBranches() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      var token;
      await Localls.getToken().then((v) => token = v);
      final response = await http.get(Uri.parse(BranchOPuser), headers: {
        "Authorization": "Bearer $token"
      }).timeout(Duration(minutes: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = json.decode(response.body);

        List<dynamic> branchesData = [];
        if (data is List) {
          branchesData = data;
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          branchesData = data['data'] is List ? data['data'] : [];
        }

        List<Branch> loadedBranches = [];
        for (var branch in branchesData) {
          try {
            loadedBranches.add(Branch(
              id: branch['_id']?.toString() ?? '',
              name: branch['name']?.toString() ?? 'غير معروف'.tr(),
            ));
          } catch (e) {
            continue;
          }
        }

        if (!mounted) return;
        setState(() {
          branches = loadedBranches;
          if (branches.isNotEmpty) {
            selectedBranch = branches.first;
          }
        });

        _loadProductionRequests();
      } else {
        throw Exception(
            '${"فشل في تحميل الفروع من السيرفر:".tr()} ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // دالة محسنة لتصفية المنتجات الموجودة في آخر طلب توريد للفرع المحدد
  List<AdditionalProduct> _filterExistingProducts(List<AdditionalProduct> allProducts) {
    if (selectedBranch == null) return allProducts;
    
    // جمع معرفات المنتجات الموجودة في آخر طلب توريد للفرع المحدد فقط
    Set<String> existingProductIds = {};
    
    for (var item in items) {
      if (!item.isBranchHeader && 
          !item.isMainProduct && 
          item.productId.isNotEmpty &&
          item.branch == selectedBranch!.name) {
        existingProductIds.add(item.productId);
      }
    }

    // تصفية المنتجات لإزالة تلك الموجودة في الطلب الحالي للفرع المحدد
    return allProducts.where((product) => !existingProductIds.contains(product.id)).toList();
  }

  // دالة للتحقق مما إذا كان المنتج موجودًا بالفعل في الفرع المحدد
  bool _isProductInCurrentBranch(String productId) {
    if (selectedBranch == null) return false;
    
    return items.any((item) => 
        !item.isBranchHeader && 
        !item.isMainProduct && 
        item.productId == productId &&
        item.branch == selectedBranch!.name);
  }

  Future<void> _loadAdditionalProducts() async {
    if (!mounted || selectedBranch == null) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(productsUrl)).timeout(Duration(minutes: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        List<dynamic> productsData = [];
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          productsData = data['data'] is List ? data['data'] : [];
        }

        List<AdditionalProduct> loadedProducts = [];
        for (var product in productsData) {
          try {
            if (product['isorderSupply'] == true) {
              loadedProducts.add(AdditionalProduct(
                id: product['_id']?.toString() ?? '',
                name: product['name']?.toString() ?? 'غير معروف'.tr(),
                package: product['packSize']?.toString() ?? '1',
                packageUnit: product['packageUnit'] is Map
                    ? (product['packageUnit']['_id']?.toString() ?? '')
                    : '',
                packageUnitName: product['packageUnit'] is Map
                    ? (product['packageUnit']['name']?.toString() ?? " ")
                    : " ",
                mainProductOP: product['mainProductOP'] is Map
                    ? (product['mainProductOP']['_id']?.toString() ?? '')
                    : '',
                mainProductName: product['mainProductOP'] is Map
                    ? (product['mainProductOP']['name']?.toString() ?? '')
                    : '',
              ));
            }
          } catch (e) {
            continue;
          }
        }

        // تصفية المنتجات بناءً على الفرع المحدد
        List<AdditionalProduct> filteredProducts = _filterExistingProducts(loadedProducts);

        if (!mounted) return;
        setState(() {
          additionalProducts = loadedProducts;
          filteredAdditionalProducts = filteredProducts;
          additionalProductControllers = {};
          for (var product in filteredAdditionalProducts) {
            additionalProductControllers[product.id] = TextEditingController(text: '0');
          }
        });
      } else {
        throw Exception('${"فشل في تحميل المنتجات الإضافية:".tr()} ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحميل المنتجات الإضافية: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _isCurrentBranchSent() {
    if (selectedBranch == null) return false;
    return branchIsSendStatus[selectedBranch!.name] ?? false;
  }

  // دالة جديدة لتجميع المنتجات حسب المنتج الرئيسي
  Map<String, List<AdditionalProduct>> _groupProductsByMainProduct() {
    Map<String, List<AdditionalProduct>> groupedProducts = {};
    
    for (var product in filteredAdditionalProducts) {
      String mainProductId = product.mainProductOP.isEmpty ? 'بدون_قسم' : product.mainProductOP;
      String mainProductName = product.mainProductName.isEmpty ? 'بدون قسم رئيسي' : product.mainProductName;
      
      if (!groupedProducts.containsKey(mainProductId)) {
        groupedProducts[mainProductId] = [];
      }
      groupedProducts[mainProductId]!.add(product);
    }
    
    return groupedProducts;
  }

  Future<void> _loadProductionRequests() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final response =
          await http.get(Uri.parse(apiUrl)).timeout(Duration(minutes: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        List<dynamic> productionData = [];
        if (data is Map<String, dynamic>) {
          if (data['data'] is List) {
            productionData = data['data'];
          } else if (data.containsKey('orders')) {
            productionData = data['orders'] is List ? data['orders'] : [];
          }
        }

        Map<String, MapEntry<String, DateTime>> latestOrdersPerBranch = {};
        Map<String, bool> branchSendStatus = {};

        for (var item in productionData) {
          try {
            final branchName = item['branch'] is Map
                ? (item['branch']['name']?.toString() ?? 'غير معروف'.tr())
                : 'غير معروف'.tr();

            final orderNameRaw = item['ordername']?.toString() ?? '';
            final regex = RegExp(
                r'طلب توريد - (\d{1,2})/(\d{1,2})/(\d{4}) - (\d{1,2}):(\d{1,2})');
            final match = regex.firstMatch(orderNameRaw);

            if (match != null) {
              final day = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              final year = int.parse(match.group(3)!);
              final hour = int.parse(match.group(4)!);
              final minute = int.parse(match.group(5)!);

              final parsedDate = DateTime(year, month, day, hour, minute);

              if (!latestOrdersPerBranch.containsKey(branchName) ||
                  parsedDate
                      .isAfter(latestOrdersPerBranch[branchName]!.value)) {
                latestOrdersPerBranch[branchName] =
                    MapEntry(orderNameRaw, parsedDate);
                branchSendStatus[branchName] = item['isSend'] ?? false;
              }
            }
          } catch (e) {
            continue;
          }
        }

        List<ProductionItem> allItems = [];
        for (var item in productionData) {
          try {
            final branchName = item['branch'] is Map
                ? (item['branch']['name']?.toString() ?? 'غير معروف'.tr())
                : 'غير معروف'.tr();

            final orderName = item['ordername']?.toString() ?? '';

            if (latestOrdersPerBranch.containsKey(branchName) &&
                latestOrdersPerBranch[branchName]!.key == orderName) {
              double requestedQty = 0;
              if (item['qty'] is int) {
                requestedQty = (item['qty'] as int).toDouble();
              } else if (item['qty'] is double) {
                requestedQty = item['qty'] as double;
              } else if (item['qty'] is String) {
                requestedQty = double.tryParse(item['qty']) ?? 0;
              }

              final newItem = ProductionItem(
                id: item['_id']?.toString() ?? '',
                productId: item['product'] is Map
                    ? (item['product']['_id']?.toString() ?? '')
                    : '',
                name: item['product'] is Map
                    ? (item['product']['name']?.toString() ?? 'غير معروف'.tr())
                    : 'غير معروف'.tr(),
                package: item['package']?.toString() ?? '0',
                requestedQty: requestedQty,
                branch: branchName,
                orderName: orderName,
                packageUnitname: item['packageUnit'] is Map
                    ? (item['packageUnit']['name']?.toString() ??
                        "")
                    : "",
                mainProductId: item['mainProductOP'] is Map
                    ? (item['mainProductOP']['_id']?.toString() ?? '')
                    : '',
                mainProductName: item['mainProductOP'] is Map
                    ? (item['mainProductOP']['name']?.toString() ?? '')
                    : '',
              );

              allItems.add(newItem);
            }
          } catch (e) {
            continue;
          }
        }

        // تجميع العناصر حسب المنتج الرئيسي مع جمع الكميات للمنتجات المتشابهة
        List<ProductionItem> groupedItems = [];
        
        // تجميع العناصر حسب الفرع أولاً
        Map<String, List<ProductionItem>> branchItemsMap = {};
        for (var item in allItems) {
          if (!branchItemsMap.containsKey(item.branch)) {
            branchItemsMap[item.branch] = [];
          }
          branchItemsMap[item.branch]!.add(item);
        }

        // بناء القائمة النهائية مع التجميع
        branchItemsMap.forEach((branch, items) {
          // إضافة عنوان الفرع
          groupedItems.add(ProductionItem(
            id: branch,
            productId: '',
            name: branch,
            package: '',
            requestedQty: 0,
            branch: branch,
            orderName: '',
            packageUnitname: '',
            isBranchHeader: true,
          ));

          // تجميع العناصر حسب المنتج الرئيسي أولاً
          Map<String, List<ProductionItem>> mainProductGroups = {};
          for (var item in items) {
            String mainProductKey = item.mainProductId.isNotEmpty 
                ? item.mainProductId 
                : 'without_main_${item.productId}';
            
            if (!mainProductGroups.containsKey(mainProductKey)) {
              mainProductGroups[mainProductKey] = [];
            }
            mainProductGroups[mainProductKey]!.add(item);
          }

          // إضافة المجموعات إلى القائمة مع جمع الكميات للمنتجات المتشابهة
          mainProductGroups.forEach((mainProductKey, subItems) {
            if (subItems.isNotEmpty) {
              // إذا كان هناك منتج رئيسي، نضيف عنوانه
              if (mainProductKey != 'without_main_${subItems.first.productId}' && 
                  subItems.first.mainProductName.isNotEmpty) {
                groupedItems.add(ProductionItem(
                  id: mainProductKey,
                  productId: mainProductKey,
                  name: subItems.first.mainProductName,
                  package: '',
                  requestedQty: 0,
                  branch: branch,
                  orderName: '',
                  packageUnitname: '',
                  isMainProduct: true,
                ));
              }
              
              // تجميع المنتجات المتشابهة في نفس المجموعة
              Map<String, ProductionItem> uniqueProducts = {};
              for (var subItem in subItems) {
                String productKey = '${subItem.productId}_${subItem.name}_${subItem.package}_${subItem.packageUnitname}';
                
                if (uniqueProducts.containsKey(productKey)) {
                  // إذا المنتج موجود مسبقاً، نجمع الكمية
                  uniqueProducts[productKey]!.requestedQty += subItem.requestedQty;
                } else {
                  // إذا المنتج جديد، نضيفه
                  uniqueProducts[productKey] = ProductionItem(
                    id: subItem.id,
                    productId: subItem.productId,
                    name: subItem.name,
                    package: subItem.package,
                    requestedQty: subItem.requestedQty,
                    branch: subItem.branch,
                    orderName: subItem.orderName,
                    packageUnitname: subItem.packageUnitname,
                    mainProductId: subItem.mainProductId,
                    mainProductName: subItem.mainProductName,
                  );
                }
              }
              
              // إضافة المنتجات المميزة إلى القائمة
              groupedItems.addAll(uniqueProducts.values);
            }
          });
        });

        if (!mounted) return;
        setState(() {
          items = groupedItems;
          branchIsSendStatus = branchSendStatus;

          if (items.isNotEmpty &&
              items.any((item) => item.orderName.isNotEmpty)) {
            lastOrderName =
                items.firstWhere((item) => item.orderName.isNotEmpty).orderName;
          }

          quantityControllers = {};
          originalQuantities = {};
          for (var item in items) {
            if (!item.isBranchHeader && !item.isMainProduct) {
              quantityControllers[item.id] = TextEditingController(
                  text: item.requestedQty.toStringAsFixed(2));
              originalQuantities[item.id] = item.requestedQty;
            }
          }

          if (selectedBranch != null) {
            _filterItems();
          }
        });
      } else {
        throw Exception(
            '${"فشل في تحميل البيانات من السيرفر:".tr()} ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _filterItems() {
    if (!mounted || selectedBranch == null) return;

    setState(() {
      filteredItems = items.where((item) {
        return item.branch == selectedBranch!.name || item.isBranchHeader;
      }).toList();
    });
  }

  Widget _buildHeaderRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isVerySmallScreen = constraints.maxWidth < 400;

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: secondaryColor.withOpacity(0.3),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isVerySmallScreen
                  ? 8
                  : isSmallScreen
                      ? 10
                      : 12,
              horizontal: isVerySmallScreen
                  ? 8
                  : isSmallScreen
                      ? 10
                      : 12,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: isSmallScreen ? 3 : 4,
                  child: Text(
                    'القسم / الصنف'.tr(),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 12
                          : isSmallScreen
                              ? 14
                              : 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  width: isSmallScreen ? 60 : 80,
                  alignment: Alignment.center,
                  child: Text(
                    'الوحدة'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 12
                          : isSmallScreen
                              ? 14
                              : 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    ' اجراء/ المطلوب'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 12
                          : isSmallScreen
                              ? 14
                              : 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdditionalProductsHeaderRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isVerySmallScreen = constraints.maxWidth < 400;

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: accentColor.withOpacity(0.3),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isVerySmallScreen
                  ? 8
                  : isSmallScreen
                      ? 10
                      : 12,
              horizontal: isVerySmallScreen
                  ? 8
                  : isSmallScreen
                      ? 10
                      : 12,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: isSmallScreen ? 3 : 4,
                  child: Text(
                    'الأصناف الإضافية'.tr(),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 12
                          : isSmallScreen
                              ? 14
                              : 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  width: isSmallScreen ? 60 : 80,
                  alignment: Alignment.center,
                  child: Text(
                    'الوحدة'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 12
                          : isSmallScreen
                              ? 14
                              : 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'الكمية'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 12
                          : isSmallScreen
                              ? 14
                              : 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShowLastOrderButton(String orderName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isVerySmallScreen = constraints.maxWidth < 400;

        bool hasAvailableBranches =
            branchIsSendStatus.values.any((isSend) => !isSend);

        return hasAvailableBranches
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          )
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: isVerySmallScreen
                                ? 20
                                : isSmallScreen
                                    ? 22
                                    : 24,
                            color: primaryColor,
                          ),
                        ),
                        label: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.8,
                          ),
                          child: Tooltip(
                            message: orderName,
                            child: Text(
                              "عرض آخر طلب توريد".tr(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.cairo(
                                fontSize: isVerySmallScreen
                                    ? 14
                                    : isSmallScreen
                                        ? 16
                                        : 18,
                                color: backgroundColor,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2,
                                    color: Colors.black.withOpacity(0.2),
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal: isVerySmallScreen
                                ? 16
                                : isSmallScreen
                                    ? 20
                                    : 24,
                            vertical: isVerySmallScreen
                                ? 10
                                : isSmallScreen
                                    ? 12
                                    : 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            showContent = true;
                          });
                          _loadProductionRequests();
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, Color(0xFFFFD700)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          )
                        ],
                      ),
                      child: (widget.canedite==true||widget.usercanedite==true)? ElevatedButton.icon(
                        icon: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.add_circle_outline,
                            size: isVerySmallScreen
                                ? 20
                                : isSmallScreen
                                    ? 22
                                    : 24,
                            color: accentColor,
                          ),
                        ),
                        label: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.8,
                          ),
                          child: Text(
                            "إضافة أصناف لطلب التوريد".tr(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.cairo(
                              fontSize: isVerySmallScreen
                                  ? 14
                                  : isSmallScreen
                                      ? 16
                                      : 18,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.2),
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal: isVerySmallScreen
                                ? 16
                                : isSmallScreen
                                    ? 20
                                    : 24,
                            vertical: isVerySmallScreen
                                ? 10
                                : isSmallScreen
                                    ? 12
                                    : 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          _loadAdditionalProducts();
                          setState(() {
                            showAdditionalProducts = true;
                            showContent = true;
                          });
                        },
                      ):Container(),
                    ),
                  ],
                ),
              )
            : Center(
                child: Text(
                  "جاري المعالجة ...".tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.7),
                        blurRadius: 10,
                        offset: const Offset(0, 0),
                      ),
                      Shadow(
                        color: Colors.purple.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              );
      },
    );
  }

  Widget _buildFilterSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isVerySmallScreen = constraints.maxWidth < 400;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmallScreen
                ? 8.0
                : isSmallScreen
                    ? 12.0
                    : 16.0,
            vertical: isVerySmallScreen ? 4.0 : 8.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: backgroundColor,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen
                          ? 10.0
                          : isSmallScreen
                              ? 14.0
                              : 16.0,
                      vertical: 8,
                    ),
                    child: DropdownButton<Branch>(
                      value: selectedBranch,
                      isExpanded: true,
                      underline: SizedBox(),
                      hint: Text('اختر الفرع'.tr(),
                          style: GoogleFonts.cairo(
                            fontSize: isVerySmallScreen
                                ? 14
                                : isSmallScreen
                                    ? 16
                                    : 18,
                            color: lightTextColor,
                            fontWeight: FontWeight.w600,
                          )),
                      icon: Icon(Icons.arrow_drop_down,
                          size: isVerySmallScreen
                              ? 24
                              : isSmallScreen
                                  ? 28
                                  : 32,
                          color: primaryColor),
                      style: GoogleFonts.cairo(
                        fontSize: isVerySmallScreen
                            ? 14
                            : isSmallScreen
                                ? 16
                                : 18,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (Branch? value) {
                        if (value != null && mounted) {
                          setState(() {
                            selectedBranch = value;
                            _filterItems();
                            
                            // إعادة تحميل المنتجات الإضافية عند تغيير الفرع
                            if (showAdditionalProducts) {
                              _loadAdditionalProducts();
                            }
                          });
                        }
                      },
                      items: branches.map((Branch branch) {
                        return DropdownMenuItem<Branch>(
                          value: branch,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen
                                  ? 6
                                  : isSmallScreen
                                      ? 8
                                      : 10,
                            ),
                            child: Text(branch.name),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductionItemRow(ProductionItem item, int index) {
    if (item.isBranchHeader) {
      return _buildBranchHeader(item);
    } else if (item.isMainProduct) {
      return _buildMainProductHeader(item);
    } else {
      return _buildSingleItemRow(item, index);
    }
  }

  Widget _buildBranchHeader(ProductionItem item) {
    return SizedBox.shrink();
  }

  Widget _buildMainProductHeader(ProductionItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isVerySmallScreen = constraints.maxWidth < 400;

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isVerySmallScreen ? 8 : 10,
              horizontal: isVerySmallScreen ? 12 : 16,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category,
                  color: primaryColor,
                  size: isVerySmallScreen ? 18 : 20,
                ),
                SizedBox(width: isVerySmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 14
                          : isSmallScreen
                              ? 16
                              : 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: primaryColor.withOpacity(0.6),
                  size: isVerySmallScreen ? 18 : 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleItemRow(ProductionItem item, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTinyScreen = constraints.maxWidth < 350;
        final isSmallScreen = constraints.maxWidth < 500;
        final isMediumScreen = constraints.maxWidth < 700;
        final isLargeScreen = constraints.maxWidth > 900;

        final horizontalPadding = isTinyScreen
            ? 6.0
            : isSmallScreen
                ? 8.0
                : 12.0;
        final verticalPadding = isTinyScreen
            ? 6.0
            : isSmallScreen
                ? 8.0
                : 10.0;
        final fontSize = isTinyScreen
            ? 11.0
            : isSmallScreen
                ? 13.0
                : isMediumScreen
                    ? 15.0
                    : 16.0;
        final iconSize = isTinyScreen
            ? 16.0
            : isSmallScreen
                ? 18.0
                : 20.0;
        final inputFieldWidth = isTinyScreen
            ? 40.0
            : isSmallScreen
                ? 45.0
                : 50.0;
        final packageWidth = isTinyScreen
            ? 45.0
            : isSmallScreen
                ? 55.0
                : isLargeScreen
                    ? 80.0
                    : 65.0;

        final currentValue =
            double.tryParse(quantityControllers[item.id]?.text ?? '0') ?? 0;
        final originalValue = originalQuantities[item.id] ?? 0;
        final hasChanges = currentValue != originalValue;

        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: hasChanges ? secondaryColor.withOpacity(0.2) : backgroundColor,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: horizontalPadding,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      flex: isLargeScreen ? 4 : 3,
                      child: Container(
                        width:
                            constraints.maxWidth * (isTinyScreen ? 0.25 : 0.3),
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.centerLeft,
                        child: Text(
                                                    textAlign: TextAlign.center,

                          item.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                          style: GoogleFonts.cairo(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),

                    Container(
                      width: packageWidth,
                      alignment: Alignment.center,
                      child: Text(
                        " ${(item.package.toString().contains("يحدد") )?" ":item.package} ${item.packageUnitname}",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 4,
                        style: GoogleFonts.cairo(
                          fontSize: fontSize - (isTinyScreen ? 1 : 0),
                          fontWeight: FontWeight.w500,
                          color: lightTextColor,
                        ),
                      ),
                    ),

                    Flexible(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                           (widget.canedite==true||widget.usercanedite==true)
                                ? IconButton(
                                    icon: Icon(Icons.remove,
                                        color: primaryColor, size: iconSize),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed: () {
                                      if (!mounted) return;
                                      setState(() {
                                        double currentValue = double.tryParse(
                                                quantityControllers[item.id]!
                                                    .text) ??
                                            0;
                                        if (currentValue > 0) {
                                          currentValue -= 1;
                                          quantityControllers[item.id]!.text =
                                              currentValue.toStringAsFixed(2);
                                          item.requestedQty = currentValue;
                                        }
                                        // التأكد من أن القيمة لا تصبح سالبة
                                        if (currentValue < 0) {
                                          quantityControllers[item.id]!.text = '0';
                                          item.requestedQty = 0;
                                        }
                                      });
                                    },
                                  )
                                : Container(),
                            SizedBox(
                              width: inputFieldWidth,
                              child: TextField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // يسمح فقط بالأرقام والنقطة
                                ],
                                readOnly:
                                    (widget.canedite==true||widget.usercanedite==true) ? false : true,
                                key: ValueKey(item.id),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                controller: quantityControllers[item.id],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: isTinyScreen
                                        ? 4
                                        : isSmallScreen
                                            ? 6
                                            : 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide:
                                        BorderSide(color: secondaryColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                        color: accentColor, width: 1.5),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (!mounted) return;
                                  
                                  // منع القيم السالبة
                                  if (value.startsWith('-')) {
                                    quantityControllers[item.id]!.text = value.replaceFirst('-', '');
                                    return;
                                  }
                                  
                                  double parsedValue = double.tryParse(value) ?? 0;
                                  
                                  // التأكد من أن القيمة لا تكون سالبة
                                  if (parsedValue < 0) {
                                    quantityControllers[item.id]!.text = '0';
                                    parsedValue = 0;
                                  }
                                  
                                  setState(() {
                                    item.requestedQty = parsedValue;
                                  });
                                },
                              ),
                            ),
                            (widget.canedite==true||widget.usercanedite==true)
                                ? IconButton(
                                    icon: Icon(Icons.add,
                                        color: primaryColor, size: iconSize),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed: () {
                                      if (!mounted) return;
                                      setState(() {
                                        double currentValue = double.tryParse(
                                                quantityControllers[item.id]!
                                                    .text) ??
                                            0;
                                        currentValue += 1;
                                        quantityControllers[item.id]!.text =
                                            currentValue.toStringAsFixed(2);
                                        item.requestedQty = currentValue;
                                      });
                                    },
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: isTinyScreen ? 8 : 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // دالة جديدة لبناء رأس المنتج الرئيسي
  Widget _buildMainProductHeaderForAdditional(String mainProductName) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.category,
              color: primaryColor,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                mainProductName,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة جديدة لبناء صف المنتج الإضافي
  Widget _buildAdditionalProductRow(AdditionalProduct product, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTinyScreen = constraints.maxWidth < 350;
        final isSmallScreen = constraints.maxWidth < 500;
        final isMediumScreen = constraints.maxWidth < 700;

        final horizontalPadding = isTinyScreen
            ? 6.0
            : isSmallScreen
                ? 8.0
                : 12.0;
        final verticalPadding = isTinyScreen
            ? 6.0
            : isSmallScreen
                ? 8.0
                : 10.0;
        final fontSize = isTinyScreen
            ? 11.0
            : isSmallScreen
                ? 13.0
                : isMediumScreen
                    ? 15.0
                    : 16.0;
        final iconSize = isTinyScreen
            ? 16.0
            : isSmallScreen
                ? 18.0
                : 20.0;
        final inputFieldWidth = isTinyScreen
            ? 40.0
            : isSmallScreen
                ? 45.0
                : 50.0;

        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: backgroundColor,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: horizontalPadding,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      flex: 3,
                      child: Container(
                        width: constraints.maxWidth * 0.3,
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          textAlign: TextAlign.center,
                          product.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                          style: GoogleFonts.cairo(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),

                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: Text(
                        "${(product.package.toString().contains("يحدد") )?" ":product.package} ${product.packageUnitName}",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 4,
                        style: GoogleFonts.cairo(
                          fontSize: fontSize - (isTinyScreen ? 1 : 0),
                          fontWeight: FontWeight.w500,
                          color: lightTextColor,
                        ),
                      ),
                    ),

                    Flexible(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove,
                                  color: primaryColor, size: iconSize),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () {
                                if (!mounted) return;
                                setState(() {
                                  double currentValue = double.tryParse(
                                          additionalProductControllers[
                                                  product.id]!
                                              .text) ??
                                      0;
                                  if (currentValue > 0) {
                                    currentValue -= 1;
                                    additionalProductControllers[product.id]!
                                        .text = currentValue.toStringAsFixed(2);
                                  }
                                  // التأكد من أن القيمة لا تصبح سالبة
                                  if (currentValue < 0) {
                                    additionalProductControllers[product.id]!.text = '0';
                                  }
                                });
                              },
                            ),
                            SizedBox(
                              width: inputFieldWidth,
                              child: TextField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // يسمح فقط بالأرقام والنقطة
                                ],
                                keyboardType:
                                    TextInputType.numberWithOptions(decimal: true),
                                controller:
                                    additionalProductControllers[product.id],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: isTinyScreen
                                        ? 4
                                        : isSmallScreen
                                            ? 6
                                            : 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide:
                                        BorderSide(color: secondaryColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                        color: accentColor, width: 1.5),
                                  ),
                                ),
                                onChanged: (value) {
                                  // منع القيم السالبة
                                  if (value.startsWith('-')) {
                                    additionalProductControllers[product.id]!.text = value.replaceFirst('-', '');
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add,
                                  color: primaryColor, size: iconSize),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () {
                                if (!mounted) return;
                                setState(() {
                                  double currentValue = double.tryParse(
                                          additionalProductControllers[
                                                  product.id]!
                                              .text) ??
                                      0;
                                  currentValue += 1;
                                  additionalProductControllers[product.id]!
                                      .text = currentValue.toStringAsFixed(2);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: isTinyScreen ? 8 : 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // دالة جديدة لبناء قائمة المنتجات الإضافية مجمعة حسب المنتج الرئيسي
  Widget _buildGroupedAdditionalProducts() {
    Map<String, List<AdditionalProduct>> groupedProducts = _groupProductsByMainProduct();
    
    if (groupedProducts.isEmpty) {
      return _buildNoAdditionalProductsMessage();
    }

    return Column(
      children: groupedProducts.entries.map((entry) {
        String mainProductId = entry.key;
        List<AdditionalProduct> products = entry.value;
        String mainProductName = products.first.mainProductName.isEmpty ? 
            'بدون قسم رئيسي' : products.first.mainProductName;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس المنتج الرئيسي
            _buildMainProductHeaderForAdditional(mainProductName),
            
            // المنتجات التابعة لهذا المنتج الرئيسي
            ...products.map((product) => _buildAdditionalProductRow(product, products.indexOf(product))).toList(),
            
            SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildNoAdditionalProductsMessage() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory,
              size: 60,
              color: secondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد منتجات إضافية متاحة'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'جميع المنتجات موجودة بالفعل في طلب التوريد الحالي'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: lightTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAllQuantities() async {
    if (!mounted) return;

    // التحقق من عدم وجود قيم أقل من الصفر قبل الحفظ
    bool hasNegativeValues = false;
    for (var item in filteredItems) {
      if (!item.isBranchHeader && !item.isMainProduct) {
        final currentValue = double.tryParse(quantityControllers[item.id]!.text) ?? 0;
        if (currentValue < 0) {
          hasNegativeValues = true;
          break;
        }
      }
    }

    if (hasNegativeValues) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن حفظ قيم أقل من الصفر'.tr()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    bool hasChanges = false;
    for (var item in filteredItems) {
      if (!item.isBranchHeader && !item.isMainProduct) {
        final currentValue =
            double.tryParse(quantityControllers[item.id]!.text) ?? 0;
        final originalValue = originalQuantities[item.id] ?? 0;

        if (currentValue != originalValue) {
          hasChanges = true;
          break;
        }
      }
    }

    if (!hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا توجد تغييرات لحفظها'.tr()),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      List<Map<String, dynamic>> updates = [];

      for (var item in filteredItems) {
        if (!item.isBranchHeader && !item.isMainProduct) {
          final newQuantity =
              double.tryParse(quantityControllers[item.id]!.text) ?? 0;
          final originalValue = originalQuantities[item.id] ?? 0;

          if (newQuantity != originalValue) {
            updates.add({"id": item.id, "qty": newQuantity});
          }
        }
      }

      int successCount = 0;
      int failCount = 0;

      for (var update in updates) {
        try {
          final response = await http
              .put(
                Uri.parse(editUrl + update["id"]),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({"qty": update["qty"]}),
              )
              .timeout(Duration(minutes: 10));

          if (response.statusCode == 200||response.statusCode == 201) {
            successCount++;
            originalQuantities[update["id"]] = update["qty"];
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
        }
      }

      if (!mounted) return;

      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "تم حفظ جميع الكميات بنجاح ".tr() +
                    "(" +
                    successCount.toString() +
                    ")",
                style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم حفظ $successCount من $failCount فشل",
                style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 3),
          ),
        );
      }

      _loadProductionRequests();
    } catch (e) {
      print(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في حفظ الكميات: ${e.toString()}',
              style: GoogleFonts.cairo(fontSize: 16)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // الحصول على اسم الطلب الحالي للفرع المحدد
  String _getCurrentOrderNameForBranch() {
    if (selectedBranch == null) return '';
    
    // البحث عن آخر طلب توريد للفرع المحدد
    for (var item in items) {
      if (item.branch == selectedBranch!.name && item.orderName.isNotEmpty) {
        return item.orderName;
      }
    }
    
    // إذا لم يتم العثور على طلب، إنشاء طلب جديد
    return "طلب توريد - ${DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.now())}";
  }

  Future<void> _addAdditionalProducts() async {
    if (!mounted || selectedBranch == null) return;

    // التحقق من عدم وجود قيم أقل من الصفر قبل الإضافة
    bool hasNegativeValues = false;
    for (var product in filteredAdditionalProducts) {
      final quantity = double.tryParse(
          additionalProductControllers[product.id]?.text ?? '0') ?? 0;
      if (quantity < 0) {
        hasNegativeValues = true;
        break;
      }
    }

    if (hasNegativeValues) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن إضافة كميات أقل من الصفر'.tr()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // استخدام اسم الطلب الحالي المعروض
      String currentOrderName = _getCurrentOrderNameForBranch();

      List<Map<String, dynamic>> productsToAdd = [];
      
      for (var product in filteredAdditionalProducts) {
        final quantity = double.tryParse(
            additionalProductControllers[product.id]?.text ?? '0') ?? 0;
        
        // التحقق مرة أخرى قبل الإضافة
        if (quantity > 0 && !_isProductInCurrentBranch(product.id)) {
          productsToAdd.add({
            "branch": selectedBranch!.id,
            "product": product.id,
            "package": product.package,
            "packageUnit": product.packageUnit,
            "qty": quantity,
            "mainProductOP": product.mainProductOP,
            "ordername": currentOrderName
          });
        }
      }

      if (productsToAdd.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا توجد أصناف للإضافة أو بعض الأصناف موجودة مسبقاً'.tr()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      int successCount = 0;
      int failCount = 0;

      // إضافة كل منتج على حدة
      for (var productData in productsToAdd) {
        try {
          final response = await http
              .post(
                Uri.parse(addProductUrl),
                headers: {'Content-Type': 'application/json'},
                body: json.encode(productData),
              )
              .timeout(Duration(minutes: 10));

          if (response.statusCode == 200 || response.statusCode == 201) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
        }
      }

      if (!mounted) return;

      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "تم إضافة جميع المنتجات بنجاح ".tr() +
                    "(" +
                    successCount.toString() +
                    ")",
                style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 3),
          ),
        );
        
        // إعادة تعيين الكميات
        for (var controller in additionalProductControllers.values) {
          controller.text = '0';
        }
        
        // إعادة تحميل البيانات
        _loadProductionRequests();
        _loadAdditionalProducts(); // إعادة تحميل المنتجات الإضافية بعد الإضافة
        
        // إخفاء قسم المنتجات الإضافية بعد الإضافة
        setState(() {
          showAdditionalProducts = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم إضافة $successCount منتج، فشل في إضافة $failCount",
                style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في إضافة المنتجات: ${e.toString()}',
              style: GoogleFonts.cairo(fontSize: 16)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildSaveAllButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isVerySmallScreen = constraints.maxWidth < 400;

        bool hasChanges = false;
        for (var item in filteredItems) {
          if (!item.isBranchHeader && !item.isMainProduct) {
            final currentValue =
                double.tryParse(quantityControllers[item.id]?.text ?? '0') ?? 0;
            final originalValue = originalQuantities[item.id] ?? 0;

            if (currentValue != originalValue) {
              hasChanges = true;
              break;
            }
          }
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmallScreen
                ? 16.0
                : isSmallScreen
                    ? 20.0
                    : 24.0,
            vertical: isVerySmallScreen ? 8.0 : 12.0,
          ),
          child: ElevatedButton.icon(
            icon: Icon(Icons.save,
                size: isVerySmallScreen
                    ? 20
                    : isSmallScreen
                        ? 22
                        : 24,
                color: Colors.white),
            label: Text('حفظ جميع الكميات'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen
                      ? 14
                      : isSmallScreen
                          ? 16
                          : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasChanges ? primaryColor : Colors.grey,
              padding: EdgeInsets.symmetric(
                horizontal: isVerySmallScreen
                    ? 20
                    : isSmallScreen
                        ? 24
                        : 28,
                vertical: isVerySmallScreen
                    ? 12
                    : isSmallScreen
                        ? 14
                        : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: hasChanges ? _saveAllQuantities : null,
          ),
        );
      },
    );
  }

  Widget _buildAddProductsButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isVerySmallScreen = constraints.maxWidth < 400;

        bool hasProductsToAdd = filteredAdditionalProducts.any((product) {
          final quantity = double.tryParse(
              additionalProductControllers[product.id]?.text ?? '0') ?? 0;
          return quantity > 0;
        });

        return  ( (widget.canedite==true||widget.usercanedite==true) && 
    !_isCurrentBranchSent())? Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmallScreen
                ? 16.0
                : isSmallScreen
                    ? 20.0
                    : 24.0,
            vertical: isVerySmallScreen ? 8.0 : 12.0,
          ),
          child: ElevatedButton.icon(
            icon: Icon(Icons.add_circle,
                size: isVerySmallScreen
                    ? 20
                    : isSmallScreen
                        ? 22
                        : 24,
                color: Colors.white),
            label: Text('إضافة المنتجات المحددة'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen
                      ? 14
                      : isSmallScreen
                          ? 16
                          : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasProductsToAdd ? accentColor : Colors.grey,
              padding: EdgeInsets.symmetric(
                horizontal: isVerySmallScreen
                    ? 20
                    : isSmallScreen
                        ? 24
                        : 28,
                vertical: isVerySmallScreen
                    ? 12
                    : isSmallScreen
                        ? 14
                        : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: hasProductsToAdd ? _addAdditionalProducts : null,
          ),
        ):Container();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Directionality(
        textDirection: flutter.TextDirection.rtl,
        child: Scaffold(
          body: Container(
            color: backgroundColor,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                final isVerySmallScreen = constraints.maxWidth < 400;

                bool isCurrentBranchSent = selectedBranch != null
                    ? branchIsSendStatus[selectedBranch!.name] ?? false
                    : false;

                return !showContent
                    ? _buildShowLastOrderButton(lastOrderName)
                    : Column(
                            children: [
                              _buildFilterSection(),
                              
                              // زر إظهار/إخفاء الأصناف الإضافية
if ( (widget.canedite==true||widget.usercanedite==true)&& 
    !_isCurrentBranchSent())                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isVerySmallScreen
                                        ? 16.0
                                        : isSmallScreen
                                            ? 20.0
                                            : 24.0,
                                    vertical: isVerySmallScreen ? 8.0 : 12.0,
                                  ),
                                  child: ElevatedButton.icon(
                                    icon: Icon(
                                      showAdditionalProducts ? Icons.visibility_off : Icons.add_circle,
                                      size: isVerySmallScreen
                                          ? 20
                                          : isSmallScreen
                                              ? 22
                                              : 24,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      showAdditionalProducts 
                                          ? 'إخفاء الأصناف الإضافية'.tr() 
                                          : 'إظهار الأصناف الإضافية'.tr(),
                                      style: GoogleFonts.cairo(
                                        fontSize: isVerySmallScreen
                                            ? 14
                                            : isSmallScreen
                                                ? 16
                                                : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: showAdditionalProducts ? primaryColor : accentColor,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isVerySmallScreen
                                            ? 20
                                            : isSmallScreen
                                                ? 24
                                                : 28,
                                        vertical: isVerySmallScreen
                                            ? 12
                                            : isSmallScreen
                                                ? 14
                                                : 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (!showAdditionalProducts) {
                                        _loadAdditionalProducts();
                                      }
                                      setState(() {
                                        showAdditionalProducts = !showAdditionalProducts;
                                      });
                                    },
                                  ),
                                ),

                              // المحتوى الرئيسي
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      // عرض آخر طلب توريد
                                      if (isCurrentBranchSent)
                                        Container(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.check_circle_outline,
                                                    size: isVerySmallScreen
                                                        ? 60
                                                        : isSmallScreen
                                                            ? 70
                                                            : 80,
                                                    color: Colors.green),
                                                SizedBox(
                                                    height: isVerySmallScreen ? 12 : 16),
                                                Text('تم إرسال طلب هذا الفرع مسبقاً'.tr(),
                                                    style: GoogleFonts.cairo(
                                                      fontSize: isVerySmallScreen
                                                          ? 16
                                                          : isSmallScreen
                                                              ? 18
                                                              : 20,
                                                      color: textColor,
                                                      fontWeight: FontWeight.w600,
                                                    )),
                                              ],
                                            ),
                                          ),
                                        )
                                      else if (isLoading)
                                        Container()
                                      else if (selectedBranch == null)
                                        Container(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.store_outlined,
                                                    size: isVerySmallScreen
                                                        ? 60
                                                        : isSmallScreen
                                                            ? 70
                                                            : 80,
                                                    color: secondaryColor),
                                                SizedBox(
                                                    height: isVerySmallScreen ? 12 : 16),
                                                Text('الرجاء اختيار فرع من القائمة'.tr(),
                                                    style: GoogleFonts.cairo(
                                                      fontSize: isVerySmallScreen
                                                          ? 16
                                                          : isSmallScreen
                                                              ? 18
                                                              : 20,
                                                      color: textColor,
                                                      fontWeight: FontWeight.w600,
                                                    )),
                                              ],
                                            ),
                                          ),
                                        )
                                      else if (filteredItems.isEmpty)
                                        Container(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.production_quantity_limits,
                                                    size: isVerySmallScreen
                                                        ? 60
                                                        : isSmallScreen
                                                            ? 70
                                                            : 80,
                                                    color: secondaryColor),
                                                SizedBox(
                                                    height: isVerySmallScreen ? 12 : 16),
                                                Text(
                                                    '${"لا توجد طلبات لفرع".tr()} ${selectedBranch!.name}',
                                                    style: GoogleFonts.cairo(
                                                      fontSize: isVerySmallScreen
                                                          ? 16
                                                          : isSmallScreen
                                                              ? 18
                                                              : 20,
                                                      color: textColor,
                                                      fontWeight: FontWeight.w600,
                                                    )),
                                              ],
                                            ),
                                          ),
                                        )
                                      else 
                                        Column(
                                          children: [
                                            if (!isSmallScreen)
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: isVerySmallScreen
                                                      ? 8.0
                                                      : isSmallScreen
                                                          ? 12.0
                                                          : 16.0,
                                                ),
                                                child: _buildHeaderRow(),
                                              ),

                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isVerySmallScreen
                                                    ? 8.0
                                                    : isSmallScreen
                                                        ? 12.0
                                                        : 16.0,
                                              ),
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                physics: NeverScrollableScrollPhysics(),
                                                itemCount: filteredItems.length,
                                                itemBuilder: (context, index) {
                                                  final item = filteredItems[index];
                                                  return _buildProductionItemRow(item, index);
                                                },
                                              ),
                                            ),

                                             (widget.canedite==true||widget.usercanedite==true)
                                                ? _buildSaveAllButton()
                                                : Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Center(
                                                      child: Text(
                                                        "غير مسموح بالتعديل".tr(),
                                                        style: GoogleFonts.cairo(
                                                            color: Colors.red,
                                                            fontWeight: FontWeight.w700),
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),

                                      // عرض الأصناف الإضافية تحت آخر طلب
                                      if (showAdditionalProducts) ...[
                                        SizedBox(height: 20),
                                        Divider(thickness: 2, color: primaryColor),
                                        Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              Text(
                                                'الأصناف الإضافية المتاحة'.tr(),
                                                style: GoogleFonts.cairo(
                                                  fontSize: isVerySmallScreen
                                                      ? 18
                                                      : isSmallScreen
                                                          ? 20
                                                          : 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: accentColor,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'للفرع: ${selectedBranch?.name ?? ""}',
                                                style: GoogleFonts.cairo(
                                                  fontSize: isVerySmallScreen
                                                      ? 14
                                                      : isSmallScreen
                                                          ? 16
                                                          : 18,
                                                  color: lightTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        if (filteredAdditionalProducts.isEmpty)
                                          _buildNoAdditionalProductsMessage()
                                        else ...[
                                          if (!isSmallScreen)
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isVerySmallScreen
                                                    ? 8.0
                                                    : isSmallScreen
                                                        ? 12.0
                                                        : 16.0,
                                              ),
                                              child: _buildAdditionalProductsHeaderRow(),
                                            ),

                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isVerySmallScreen
                                                  ? 8.0
                                                  : isSmallScreen
                                                      ? 12.0
                                                      : 16.0,
                                            ),
                                            child: _buildGroupedAdditionalProducts(),
                                          ),
                                          _buildAddProductsButton(),
                                          SizedBox(height: 20),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class Branch {
  final String id;
  final String name;

  Branch({required this.id, required this.name});
}

class ProductionItem {
  final String id;
  final String productId;
  final String name;
  final String package;
  double requestedQty;
  final String branch;
  final String orderName;
  final String mainProductId;
  final String mainProductName;
  final bool isMainProduct;
  final bool isBranchHeader;
  final String packageUnitname;

  ProductionItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.package,
    required this.requestedQty,
    required this.branch,
    required this.orderName,
    this.mainProductId = '',
    this.mainProductName = '',
    this.isMainProduct = false,
    this.isBranchHeader = false,
    String? packageUnitname,
  }) : packageUnitname = packageUnitname ?? "";
}

class AdditionalProduct {
  final String id;
  final String name;
  final String package;
  final String packageUnit;
  final String packageUnitName;
  final String mainProductOP;
  final String mainProductName;

  AdditionalProduct({
    required this.id,
    required this.name,
    required this.package,
    required this.packageUnit,
    required this.packageUnitName,
    required this.mainProductOP,
    required this.mainProductName,
  });
}