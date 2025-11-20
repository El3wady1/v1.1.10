import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:saladafactory/features/home/presentation/view/widget/bannnerHome.dart';
import 'package:saladafactory/features/send/presentation/view/widget/lastSendProductionSupply.dart'
    show LastsendproductionSupplyview;
import 'package:saladafactory/features/send/presentation/view/widget/lastSendView.dart';
import 'package:saladafactory/features/send/presentation/view/widget/sendSupplyview.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter/material.dart' as material;

class Sendbodyview extends StatefulWidget {
  final String role;
  Sendbodyview({required this.role});

  @override
  _SendbodyviewState createState() => _SendbodyviewState();
}

class _SendbodyviewState extends State<Sendbodyview>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<Widget> _screens = [
    ProductionBodyView(role: 'admin'),
    SendSupplyView(role: 'admin'),
    Lastsendview(),
    LastsendproductionSupplyview()
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "الارسال".tr(),
          style: TextStyle(
            fontSize: isVerySmallScreen ? 17 : isSmallScreen ? 19 : 21,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF74826A),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF74826A),
        selectedItemColor: Color(0xFFEDBE2C),
        unselectedItemColor: Colors.white70,
        selectedFontSize: isVerySmallScreen ? 11 : 12,
        unselectedFontSize: isVerySmallScreen ? 10 : 11,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing_sharp, size: 20),
            label: "إنتاج".tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_send_rounded, size: 20),
            label: "توريد".tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: 20),
            label: "آخرانتاج".tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: 20),
            label: "آخر توريد".tr(),
          ),
        ],
      ),
    );
  }
}

class ProductionBodyView extends StatefulWidget {
  final String role;
  ProductionBodyView({required this.role});

  @override
  _ProductionBodyViewState createState() => _ProductionBodyViewState();
}

class _ProductionBodyViewState extends State<ProductionBodyView> {
  List<ProductionItem> items = [];
  List<ProductionItem> filteredItems = [];
  List<AdditionalProduct> additionalProducts = [];
  List<AdditionalProduct> filteredAdditionalProducts = [];
  Map<String, TextEditingController> quantityControllers = {};
  bool isLoading = false;
  bool isLoadingAdditional = false;
  
  // API URLs
  String apiUrl = "${Apiendpoints.baseUrl}${Apiendpoints.orderProduction.getOrderPof2Days}";
  String additionalProductsUrl = "${Apiendpoints.baseUrl}${Apiendpoints.productOP.getAll}";
  String submitUrl = "${Apiendpoints.baseUrl + Apiendpoints.production.request}";
  String branchesUrl = "${Apiendpoints.baseUrl}${Apiendpoints.branch.getall}";

  // Colors
  final Color primaryColor = Color(0xFF74826A);
  final Color accentColor = Color(0xFFEDBE2C);
  final Color secondaryColor = Color(0xFFCDBCA2);
  final Color backgroundColor = Color(0xFFF3F4EF);
  final Color textColor = Color(0xFF333333);
  final Color lightTextColor = Color(0xFF666666);

  List<Branch> branches = [];
  Branch? selectedBranch;
  bool showAdditionalProducts = false;
  List<String> orderIds = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _loadProductionRequests();
    _loadAdditionalProducts();
  }

  @override
  void dispose() {
    quantityControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadBranches() async {
    if (!mounted) return;

    try {
      print("Fetching branches from: $branchesUrl");
      final response = await http.get(Uri.parse(branchesUrl)).timeout(Duration(minutes:20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Branches API Response: $data");

        final List<dynamic> branchesData = data['data'] ?? [];
        print("Found ${branchesData.length} branches");

        List<Branch> loadedBranches = [];
        for (var branch in branchesData) {
          try {
            final newBranch = Branch(
              id: branch['_id'] ?? '',
              name: branch['name'] ?? 'غير معروف'.tr(),
            );
            loadedBranches.add(newBranch);
          } catch (e) {
            print("Error creating branch: $e");
            continue;
          }
        }

        if (!mounted) return;
        setState(() {
          branches = loadedBranches;
          if (selectedBranch == null && branches.isNotEmpty) {
            selectedBranch = branches.first;
            _filterItems();
          }
        });
      } else {
        print("Failed to load branches: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading branches: $e");
    }
  }

  Future<void> _loadAdditionalProducts() async {
    if (!mounted) return;

    setState(() => isLoadingAdditional = true);

    try {
      print("Fetching additional products from: $additionalProductsUrl");
      final response = await http
          .get(Uri.parse(additionalProductsUrl))
          .timeout(Duration(minutes:20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Additional Products API Response: $data");

        final List<dynamic> productsData = data['data'] ?? [];
        print("Found ${productsData.length} additional products");

        List<AdditionalProduct> loadedProducts = [];
        for (var product in productsData) {
          try {
            if (product['isorderProduction'] == true) {
              final newProduct = AdditionalProduct(
                id: product['_id'] ?? '',
                name: product['name'] ?? 'غير معروف'.tr(),
                package: product['packSize']?.toString() ?? '0',
                packageUnitname: product['packageUnit']?['name'],
                mainProductId: product['mainProductOP']?['_id'] ?? '',
                mainProductName: product['mainProductOP']?['name'] ?? '',
                mainProductOrder: product['mainProductOP']?['order'] ?? 0,
                branchId: product['branch']?['_id'] ?? '',
                branchName: product['branch']?['name'] ?? '',
              );
              loadedProducts.add(newProduct);
              print('تم تحميل المنتج الإضافي: ${newProduct.name} - ID: ${newProduct.id} - الفرع: ${newProduct.branchName}');
            } else {
              print("تم تجاهل المنتج: ${product['name']} لأنه isorderSupply != true");
            }
          } catch (e) {
            print("Error creating additional product: $e");
            continue;
          }
        }

        if (!mounted) return;
        setState(() {
          additionalProducts = loadedProducts;
          _filterAdditionalProducts();
          for (var product in filteredAdditionalProducts) {
            if (!quantityControllers.containsKey(product.id)) {
              quantityControllers[product.id] = TextEditingController(text: '0');
              print('تم تهيئة المتحكم للمنتج: ${product.name}');
            }
          }
        });
      } else {
        print("Failed to load additional products: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading additional products: $e");
    } finally {
      if (mounted) {
        setState(() => isLoadingAdditional = false);
      }
    }
  }

  void _filterAdditionalProducts() {
    if (selectedBranch == null) {
      setState(() {
        filteredAdditionalProducts = [];
      });
      return;
    }

    setState(() {
      filteredAdditionalProducts = additionalProducts.where((product) {
        if (product.branchId.isNotEmpty) {
          return product.branchId == selectedBranch!.id;
        }
        return true;
      }).toList();

      print('المنتجات الإضافية للفرع ${selectedBranch!.name}: ${filteredAdditionalProducts.length}');
      
      if (filteredAdditionalProducts.isEmpty) {
        showAdditionalProducts = false;
      }
    });
  }

  Future<void> _loadProductionRequests() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      print("Fetching production data from: $apiUrl");
      final response = await http.get(Uri.parse(apiUrl)).timeout(Duration(minutes:20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data");

        final List<dynamic> productionData = data['data'] ?? [];
        print("Found ${productionData.length} production items");

        // Map to store latest order for each branch
        Map<String, MapEntry<String, DateTime>> latestOrdersPerBranch = {};
        Set<String> uniqueBranches = {};

        // First pass: Find the latest order for each branch
        for (var item in productionData) {
          try {
            final branchName = item['branch']['name'] ?? 'غير معروف'.tr();
            uniqueBranches.add(branchName);

            final orderNameRaw = item['ordername'] ?? '';
            final regex = RegExp(r'طلب انتاج - (\d{1,2})/(\d{1,2})/(\d{4}) - (\d{1,2}):(\d{1,2})');
            final match = regex.firstMatch(orderNameRaw);

            if (match != null) {
              final day = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              final year = int.parse(match.group(3)!);
              final hour = int.parse(match.group(4)!);
              final minute = int.parse(match.group(5)!);

              final parsedDate = DateTime(year, month, day, hour, minute);

              if (!latestOrdersPerBranch.containsKey(branchName) ||
                  parsedDate.isAfter(latestOrdersPerBranch[branchName]!.value)) {
                latestOrdersPerBranch[branchName] = MapEntry(orderNameRaw, parsedDate);
              }
            }
          } catch (e) {
            print("Error processing order: $e");
            continue;
          }
        }

        // Second pass: Collect all items from the latest orders
        List<ProductionItem> allItems = [];
        for (var item in productionData) {
          try {
            final branchName = item['branch']['name'] ?? 'غير معروف'.tr();
            final orderName = item['ordername'] ?? '';

            if (latestOrdersPerBranch.containsKey(branchName) &&
                latestOrdersPerBranch[branchName]!.key == orderName &&
                item['isSend'] == false) {
              if (!orderIds.contains(item['_id'])) {
                orderIds.add(item['_id']);
              }

              final newItem = ProductionItem(
                id: item['_id'] ?? '',
                productId: item['product']['_id'] ?? '',
                name: item['product']['name'] ?? 'غير معروف'.tr(),
                package: item['package']?.toString() ?? '0',
                requestedQty: (item['qty'] is int)
                    ? (item['qty'] as int).toDouble()
                    : (item['qty'] as double),
                branch: branchName,
                orderName: orderName,
                packageUnitname: item['packageUnit']?['name'] ?? "",
                mainProductId: item['mainProductOP']?['_id'] ?? '',
                mainProductName: item['mainProductOP']?['name'] ?? '',
                mainProductOrder: item['mainProductOP']?['order'] ?? 0,
              );

              allItems.add(newItem);
            }
          } catch (e) {
            print("Error creating production item: $e");
            continue;
          }
        }

        // تجميع العناصر حسب المنتج الرئيسي مع جمع الكميات للمنتجات المتشابهة
        List<ProductionItem> groupedItems = _groupAndSortItems(allItems);

        if (!mounted) return;
        setState(() {
          items = groupedItems;
          quantityControllers = {};
          for (var item in items) {
            if (!item.isBranchHeader && !item.isMainProduct) {
              quantityControllers[item.id] = TextEditingController(
                  text: item.requestedQty.toStringAsFixed(2));
            }
          }

          for (var product in filteredAdditionalProducts) {
            quantityControllers[product.id] = TextEditingController(text: '0');
          }
        });
      } else {
        throw Exception('${"فشل في تحميل البيانات من السيرفر:".tr()} ${response.statusCode}');
      }
    } catch (e) {
      print("Error loading production requests: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<ProductionItem> _groupAndSortItems(List<ProductionItem> allItems) {
    List<ProductionItem> groupedItems = [];
    
    // تجميع العناصر حسب الفرع أولاً
    Map<String, List<ProductionItem>> branchItemsMap = {};
    for (var item in allItems) {
      if (!branchItemsMap.containsKey(item.branch)) {
        branchItemsMap[item.branch] = [];
      }
      branchItemsMap[item.branch]!.add(item);
    }

    // بناء القائمة النهائية مع التجميع والترتيب
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

      // تحويل الـ Map إلى قائمة وترتيبها حسب حقل order
      List<MapEntry<String, List<ProductionItem>>> sortedMainProducts = 
          mainProductGroups.entries.toList()
            ..sort((a, b) {
              // الحصول على قيمة order من العنصر الأول في كل مجموعة
              int orderA = a.value.first.mainProductOrder;
              int orderB = b.value.first.mainProductOrder;
              return orderA.compareTo(orderB);
            });

      // إضافة المجموعات المرتبة إلى القائمة
      for (var entry in sortedMainProducts) {
        String mainProductKey = entry.key;
        List<ProductionItem> subItems = entry.value;

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
              mainProductOrder: subItems.first.mainProductOrder,
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
                mainProductOrder: subItem.mainProductOrder,
              );
            }
          }
          
          // إضافة المنتجات المميزة إلى القائمة
          groupedItems.addAll(uniqueProducts.values);
        }
      }
    });

    return groupedItems;
  }

  void _filterItems() {
    if (!mounted || selectedBranch == null) return;

    setState(() {
      filteredItems = items.where((item) {
        return item.branch == selectedBranch!.name || item.isBranchHeader;
      }).toList();
      
      _filterAdditionalProducts();
    });
  }

  bool get _isQadiBranch {
    return selectedBranch?.name.toLowerCase().contains('قاضي') == true;
  }

  bool get _hasAdditionalProductsForCurrentBranch {
    return filteredAdditionalProducts.isNotEmpty;
  }

  bool get _hasRequestsForCurrentBranch {
    return filteredItems.isNotEmpty && filteredItems.any((item) => !item.isBranchHeader && !item.isMainProduct);
  }

  bool get _shouldShowAdditionalProductsButton {
    return !_isQadiBranch && 
           _hasAdditionalProductsForCurrentBranch && 
           _hasRequestsForCurrentBranch;
  }

  void _validateAndUpdateQuantity(String itemId, String newValue) {
    if (!mounted) return;
    
    double? parsedValue = double.tryParse(newValue);
    
    if (parsedValue == null || parsedValue < 0) {
      quantityControllers[itemId]!.text = '0';
      setState(() {
        var item = items.firstWhere((element) => element.id == itemId, orElse: () => ProductionItem(
          id: '', productId: '', name: '', package: '', requestedQty: 0, branch: '', orderName: ''
        ));
        if (item.id.isNotEmpty) {
          item.requestedQty = 0;
        }
      });
    } else {
      setState(() {
        var item = items.firstWhere((element) => element.id == itemId, orElse: () => ProductionItem(
          id: '', productId: '', name: '', package: '', requestedQty: 0, branch: '', orderName: ''
        ));
        if (item.id.isNotEmpty) {
          item.requestedQty = parsedValue;
        }
      });
    }
  }

  void _validateAndUpdateAdditionalQuantity(String productId, String newValue) {
    if (!mounted) return;
    
    double? parsedValue = double.tryParse(newValue);
    
    if (parsedValue == null || parsedValue < 0) {
      quantityControllers[productId]!.text = '0';
    }
  }

  Widget _buildHeaderRow() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;
    final isLargeScreen = screenSize.width > 600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: secondaryColor.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isVerySmallScreen ? 10 : isSmallScreen ? 12 : 14,
          horizontal: isVerySmallScreen ? 8 : isSmallScreen ? 12 : 16,
        ),
        child: Row(
          children: [
            Expanded(
              flex: isLargeScreen ? 4 : 3,
              child: Text(
                'القسم / الصنف'.tr(),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 12 : isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            Container(
              width: isLargeScreen ? 80 : (isVerySmallScreen ? 50 : isSmallScreen ? 60 : 70),
              alignment: Alignment.center,
              child: Text(
                'الوحدة'.tr(),
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 15 : 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            Expanded(
              flex: isLargeScreen ? 2 : 2,
              child: Text(
                'المطلوب'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 14 : isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 8.0 : isSmallScreen ? 12.0 : 16.0,
        vertical: isVerySmallScreen ? 4.0 : 8.0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: backgroundColor,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 10.0 : isSmallScreen ? 14.0 : 18.0,
                      vertical: 10,
                    ),
                    child: DropdownButton<Branch>(
                      value: selectedBranch,
                      isExpanded: true,
                      underline: SizedBox(),
                      hint: Text(
                        'اختر الفرع'.tr(),
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 15 : isSmallScreen ? 17 : 19,
                          color: lightTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        size: isVerySmallScreen ? 22 : isSmallScreen ? 26 : 30,
                        color: primaryColor,
                      ),
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 15 : isSmallScreen ? 17 : 19,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (value) {
                        if (value != null && mounted) {
                          setState(() {
                            selectedBranch = value;
                            showAdditionalProducts = false;
                            _filterItems();
                          });
                        }
                      },
                      items: branches.map((branch) {
                        return DropdownMenuItem<Branch>(
                          value: branch,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 6 : isSmallScreen ? 10 : 14,
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
          SizedBox(height: 8),
          if (_shouldShowAdditionalProductsButton)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showAdditionalProducts = !showAdditionalProducts;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: showAdditionalProducts ? primaryColor : secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(showAdditionalProducts ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                  SizedBox(width: 8),
                  Text(
                    showAdditionalProducts ? "إخفاء الأصناف الإضافية".tr() : "إظهار الأصناف الإضافية".tr(),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
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

  Widget _buildAdditionalProductsGrouped() {
    Map<String, List<AdditionalProduct>> groupedProducts = {};
    
    for (var product in filteredAdditionalProducts) {
      String mainProductKey = product.mainProductId.isNotEmpty 
          ? product.mainProductId 
          : 'without_main';
      
      if (!groupedProducts.containsKey(mainProductKey)) {
        groupedProducts[mainProductKey] = [];
      }
      groupedProducts[mainProductKey]!.add(product);
    }

    // ترتيب المنتجات الإضافية حسب حقل order
    List<MapEntry<String, List<AdditionalProduct>>> sortedGroups = 
        groupedProducts.entries.toList()
          ..sort((a, b) {
            int orderA = a.value.first.mainProductOrder;
            int orderB = b.value.first.mainProductOrder;
            return orderA.compareTo(orderB);
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'الأصناف الإضافية'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
        ),
        SizedBox(height: 8),
        
        ...sortedGroups.map((entry) {
          String mainProductId = entry.key;
          List<AdditionalProduct> products = entry.value;
          
          if (mainProductId != 'without_main' && products.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainProductHeaderForAdditional(products.first.mainProductName),
                
                ...products.map((product) => _buildAdditionalProductRow(
                  product, 
                  filteredAdditionalProducts.indexOf(product)
                )).toList(),
                
                SizedBox(height: 8),
              ],
            );
          } else {
            return Column(
              children: [
                ...products.map((product) => _buildAdditionalProductRow(
                  product, 
                  filteredAdditionalProducts.indexOf(product)
                )).toList(),
              ],
            );
          }
        }).toList(),
      ],
    );
  }

  Widget _buildMainProductHeaderForAdditional(String mainProductName) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 12,
      ),
      child: Row(
        children: [
          Icon(
            Icons.category,
            color: primaryColor,
            size: isVerySmallScreen ? 16 : 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              mainProductName,
              style: TextStyle(
                fontSize: isVerySmallScreen ? 14 : isSmallScreen ? 15 : 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalProductRow(AdditionalProduct product, int index) {
    final width = MediaQuery.of(context).size.width;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: width * 0.02),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: backgroundColor.withOpacity(0.7),
      child: Padding(
        padding: EdgeInsets.all(width * 0.02),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      product.name,
                      style: TextStyle(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${product.package} ${product.packageUnitname}",
                    style: TextStyle(
                      fontSize: width * 0.035,
                      fontWeight: FontWeight.w500,
                      color: lightTextColor,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, color: primaryColor, size: width * 0.06),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (!mounted) return;
                      setState(() {
                        double currentValue = double.tryParse(quantityControllers[product.id]!.text) ?? 0;
                        if (currentValue > 0) {
                          currentValue -= 1;
                          quantityControllers[product.id]!.text = currentValue.toStringAsFixed(2);
                          _validateAndUpdateAdditionalQuantity(product.id, currentValue.toStringAsFixed(2));
                        } else {
                          quantityControllers[product.id]!.text = '0';
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      key: ValueKey(product.id),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: quantityControllers[product.id],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: width * 0.015,
                          horizontal: width * 0.01,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: secondaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: accentColor, width: 1.5),
                        ),
                      ),
                      onChanged: (value) {
                        _validateAndUpdateAdditionalQuantity(product.id, value);
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: primaryColor, size: width * 0.06),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (!mounted) return;
                      setState(() {
                        double currentValue = double.tryParse(quantityControllers[product.id]!.text) ?? 0;
                        currentValue += 1;
                        quantityControllers[product.id]!.text = currentValue.toStringAsFixed(2);
                        _validateAndUpdateAdditionalQuantity(product.id, currentValue.toStringAsFixed(2));
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchHeader(ProductionItem item) {
    return Container();
  }

  Widget _buildMainProductHeader(ProductionItem item) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    return Container(
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
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 12,
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
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 15 : isSmallScreen ? 16 : 17,
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
  }

  Widget _buildSingleItemRow(ProductionItem item, int index) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isVerySmallScreen ? 6 : isSmallScreen ? 8 : 10,
          horizontal: isVerySmallScreen ? 6 : isSmallScreen ? 10 : 14,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 10 : isSmallScreen ? 11 : 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (item.mainProductName.isNotEmpty)
                    Text(
                      item.mainProductName,
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 8 : isSmallScreen ? 9 : 10,
                        fontWeight: FontWeight.w400,
                        color: lightTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                "${item.package} ${item.packageUnitname}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 12 : isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w500,
                  color: lightTextColor,
                ),
              ),
            ),

            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, color: primaryColor, size: isVerySmallScreen ? 18 : 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (!mounted) return;
                      setState(() {
                        double currentValue = double.tryParse(quantityControllers[item.id]?.text ?? "0") ?? 0;
                        if (currentValue > 0) {
                          currentValue -= 1;
                          quantityControllers[item.id]?.text = currentValue.toStringAsFixed(0);
                          _validateAndUpdateQuantity(item.id, currentValue.toStringAsFixed(0));
                        } else {
                          quantityControllers[item.id]?.text = '0';
                          _validateAndUpdateQuantity(item.id, '0');
                        }
                      });
                    },
                  ),

                  Expanded(
                    child: SizedBox(
                      height: isVerySmallScreen ? 36 : isSmallScreen ? 40 : 45,
                      child: TextField(
                        key: ValueKey(item.id),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        controller: quantityControllers[item.id],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          isDense: false,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: secondaryColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: accentColor, width: 1.5),
                          ),
                        ),
                        onChanged: (value) {
                          _validateAndUpdateQuantity(item.id, value);
                        },
                      ),
                    ),
                  ),

                  IconButton(
                    icon: Icon(Icons.add, color: primaryColor, size: isVerySmallScreen ? 18 : 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (!mounted) return;
                      setState(() {
                        double currentValue = double.tryParse(quantityControllers[item.id]?.text ?? "0") ?? 0;
                        currentValue += 1;
                        quantityControllers[item.id]?.text = currentValue.toStringAsFixed(0);
                        _validateAndUpdateQuantity(item.id, currentValue.toStringAsFixed(0));
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    if (!mounted || selectedBranch == null) return;

    final screenWidth = MediaQuery.of(context).size.width;

    double getResponsiveValue({
      required double normal,
      required double small,
      required double verySmall,
    }) {
      if (screenWidth < 350) return verySmall;
      if (screenWidth < 400) return small;
      return normal;
    }

    SizedBox _verticalSpace() => SizedBox(height: getResponsiveValue(normal: 20, small: 16, verySmall: 12));
    SizedBox _horizontalSpace() => SizedBox(width: getResponsiveValue(normal: 18, small: 14, verySmall: 10));

    Widget _buildTextButton(String text, VoidCallback onPressed) {
      return TextButton(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: EdgeInsets.symmetric(
            horizontal: getResponsiveValue(normal: 22, small: 18, verySmall: 14),
            vertical: getResponsiveValue(normal: 14, small: 12, verySmall: 10),
          ),
        ),
        child: Text(
          text.tr(),
          style: TextStyle(
            fontSize: getResponsiveValue(normal: 18, small: 17, verySmall: 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: onPressed,
      );
    }

    Widget _buildElevatedButton(String text, VoidCallback onPressed) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.symmetric(
            horizontal: getResponsiveValue(normal: 26, small: 22, verySmall: 18),
            vertical: getResponsiveValue(normal: 14, small: 12, verySmall: 10),
          ),
        ),
        child: Text(
          text.tr(),
          style: TextStyle(
            fontSize: getResponsiveValue(normal: 18, small: 17, verySmall: 16),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onPressed: onPressed,
      );
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: backgroundColor,
        child: Directionality(
          textDirection: material.TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.all(getResponsiveValue(normal: 22, small: 18, verySmall: 14)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'تأكيد الارسال'.tr(),
                    style: TextStyle(
                      fontSize: getResponsiveValue(normal: 22, small: 20, verySmall: 18),
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                _verticalSpace(),
                Text(
                  'هل أنت متأكد من الكميات المنتجة؟'.tr(),
                  style: TextStyle(
                    fontSize: getResponsiveValue(normal: 18, small: 17, verySmall: 16),
                    color: textColor,
                  ),
                ),
                _verticalSpace(),
                Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      color: primaryColor,
                      size: getResponsiveValue(normal: 24, small: 22, verySmall: 20),
                    ),
                    _horizontalSpace(),
                    Flexible(
                      child: Text(
                        '${"سيتم إرسال الكميات المحددة - فرع".tr()} ${selectedBranch!.name}',
                        style: TextStyle(
                          fontSize: getResponsiveValue(normal: 16, small: 15, verySmall: 14),
                          color: lightTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                _verticalSpace(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildTextButton('إلغاء', () => Navigator.pop(context)),
                    _horizontalSpace(),
                    _buildElevatedButton('تأكيد', () async {
                      Navigator.pop(context);
                      _submitProductionRequest();
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitProductionRequest() async {
    if (!mounted || selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("لم يتم اختيار فرع"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final itemsToSubmit = filteredItems
          .where((item) => item.requestedQty > 0 && !item.isMainProduct && !item.isBranchHeader)
          .map((item) => {"productId": item.productId, "qty": item.requestedQty})
          .toList();

      print('المنتجات الأساسية: ${itemsToSubmit.length}');

      if (!_isQadiBranch && _hasAdditionalProductsForCurrentBranch) {
        for (var product in filteredAdditionalProducts) {
          final controller = quantityControllers[product.id];
          if (controller != null) {
            double qty = double.tryParse(controller.text) ?? 0;
            print('المنتج الإضافي: ${product.name}, الكمية: $qty');

            if (qty > 0) {
              itemsToSubmit.add({"productId": product.id, "qty": qty});
              print('تم إضافة المنتج الإضافي: ${product.name}');
            }
          } else {
            print('لم يتم العثور على متحكم للكمية للمنتج: ${product.name}');
          }
        }
      }

      print('إجمالي العناصر المرسلة: ${itemsToSubmit.length}');
      print('بيانات الإرسال: $itemsToSubmit');

      if (itemsToSubmit.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا توجد أصناف للإرسال'.tr()),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      var userId;
      await Localls.getUserID().then((v) => userId = v);

      final response = await http
          .post(
            Uri.parse(submitUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "isAdmin": true,
              "items": itemsToSubmit,
              "branch": selectedBranch!.id,
              "isSend": true,
              "userID": userId
            }),
          )
          .timeout(Duration(minutes:20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(response.body);

        if (orderIds.isNotEmpty) {
          int successCount = 0;
          int failCount = 0;

          final branchOrderIds = items
              .where((item) => !item.isBranchHeader && !item.isMainProduct && item.branch == selectedBranch!.name)
              .map((item) => item.id)
              .toSet()
              .toList();

          print("طلبات الفرع المحدد: ${branchOrderIds.length}");

          for (String orderId in branchOrderIds) {
            try {
              await updateOrderIsSended(orderId: orderId, isSend: true);
              successCount++;
              print("✅ تم تحديث حالة الطلب $orderId بنجاح");
            } catch (e) {
              failCount++;
              print("⚠️ فشل في تحديث حالة الطلب $orderId: $e");
            }
          }

          print("✅ تم تحديث $successCount طلب بنجاح، فشل في تحديث $failCount طلب");

          if (failCount > 0 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تحديث $successCount طلب بنجاح، ولكن فشل في تحديث $failCount طلب'.tr()),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          print("⚠️ لا توجد طلبات لتحديث حالتها");
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${data["message"] ?? "تمت العملية بنجاح"}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.pop(context);

        await _loadProductionRequests();
        await _loadAdditionalProducts();

        if (!_isQadiBranch && _hasAdditionalProductsForCurrentBranch) {
          for (var product in filteredAdditionalProducts) {
            if (quantityControllers.containsKey(product.id)) {
              quantityControllers[product.id]!.text = '0';
            }
          }
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'فشل التوريد');
      }
    } catch (e) {
      print("Error submitting SendSupply: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في العملية: ${e.toString()}',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Directionality(
        textDirection: material.TextDirection.rtl,
        child: Container(
          color: backgroundColor,
          child: Column(
            children: [
              _buildFilterSection(),
              if (isLoading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      strokeWidth: 4,
                    ),
                  ),
                )
              else if (selectedBranch == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_outlined,
                            size: isVerySmallScreen ? 55 : isSmallScreen ? 65 : 75,
                            color: secondaryColor),
                        SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 20),
                        Text('الرجاء اختيار فرع من القائمة'.tr(),
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                )
              else if (!_hasRequestsForCurrentBranch && !_hasAdditionalProductsForCurrentBranch)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.production_quantity_limits,
                            size: isVerySmallScreen ? 55 : isSmallScreen ? 65 : 75,
                            color: secondaryColor),
                        SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 20),
                        Text('${"لا توجد طلبات لفرع".tr()} ${selectedBranch!.name}',
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                )
              else ...[
                if (!isSmallScreen)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 8.0 : isSmallScreen ? 12.0 : 16.0,
                    ),
                    child: _buildHeaderRow(),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 8.0 : isSmallScreen ? 12.0 : 16.0,
                    ),
                    child: ListView(
                      children: [
                        if (_hasRequestsForCurrentBranch)
                          ...filteredItems
                              .where((item) => !item.isBranchHeader)
                              .map((item) => _buildProductionItemRow(item, filteredItems.indexOf(item)))
                              .toList(),

                        if (showAdditionalProducts && _hasAdditionalProductsForCurrentBranch && !_isQadiBranch)
                          _buildAdditionalProductsGrouped(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isVerySmallScreen ? 10.0 : isSmallScreen ? 14.0 : 18.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: accentColor,
                        padding: EdgeInsets.symmetric(
                          vertical: isVerySmallScreen ? 14 : isSmallScreen ? 16 : 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: isVerySmallScreen ? 20 : isSmallScreen ? 24 : 28),
                          SizedBox(width: isVerySmallScreen ? 6 : isSmallScreen ? 8 : 10),
                          Text('الارسال'.tr(),
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                      onPressed: selectedBranch == null ? null : _showConfirmationDialog,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProductionItem {
  String id;
  String productId;
  String name;
  String package;
  String packageUnitname;
  double requestedQty;
  String branch;
  String orderName;
  String mainProductId;
  String mainProductName;
  int mainProductOrder;
  bool isMainProduct;
  bool isBranchHeader;

  ProductionItem({
    required this.id,
    required this.productId,
    required this.name,
    required String package,
    String? packageUnitname,
    required this.requestedQty,
    required this.branch,
    required this.orderName,
    this.mainProductId = '',
    this.mainProductName = '',
    this.mainProductOrder = 0,
    this.isMainProduct = false,
    this.isBranchHeader = false,
  }) : package = (package == "لم يحدد") ? "" : package,
       packageUnitname = packageUnitname ?? "";
}

class AdditionalProduct {
  String id;
  String name;
  String package;
  String packageUnitname;
  String mainProductId;
  String mainProductName;
  int mainProductOrder;
  String branchId;
  String branchName;

  AdditionalProduct({
    required this.id,
    required this.name,
    required String package,
    String? packageUnitname,
    this.mainProductId = '',
    this.mainProductName = '',
    this.mainProductOrder = 0,
    this.branchId = '',
    this.branchName = '',
  }) : package = (package == "لم يحدد") ? "" : package,
       packageUnitname = packageUnitname ?? "";
}

class Branch {
  String id;
  String name;

  Branch({
    required this.id,
    required this.name,
  });
}

Future updateOrderIsSended({
  required String orderId,
  bool isSend = true,
}) async {
  final url = Uri.parse("${Apiendpoints.baseUrl}${Apiendpoints.orderProduction.isSend}$orderId");

  final response = await http.put(
    url,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({"isSend": isSend}),
  ).timeout(Duration(minutes: 20));

  if (response.statusCode == 200) {
    print("✅ Success: ${response.body}");
    return true;
  } else {
    print("⚠️ Error: ${response.statusCode} => ${response.body}");
    throw Exception("Failed to update order: ${response.statusCode}");
  }
}