import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class Production_Supply extends StatefulWidget {
  final String role;
  Production_Supply({required this.role});

  @override
  _Production_SupplyState createState() => _Production_SupplyState();
}

class _Production_SupplyState extends State<Production_Supply> {
  List<ProductionItem> items = [];
  List<ProductionItem> filteredItems = [];
  bool isLoading = false;
  String apiUrl =
      "${Apiendpoints.baseUrl}${Apiendpoints.orderSupply.getOrderSof2Days}";

  // ألوان متناسقة
  final Color primaryColor = Color(0xFF2E5E3A);
  final Color accentColor = Color(0xFFE6B905);
  final Color secondaryColor = Color(0xFF8B9E7E);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textColor = Color(0xFF333333);
  final Color lightTextColor = Color(0xFF666666);

  // متغيرات الفلترة المتعددة للفئات
  List<String> allCategories = [];
  List<String> selectedCategories = [];
  List<MultiSelectItem<String>> categoryItems = [];

  // متغيرات Dropdown للفروع
  List<String> allBranches = [];
  String? selectedBranch;
  List<DropdownMenuItem<String>> branchDropdownItems = [];

  @override
  void initState() {
    super.initState();
    _loadProductionRequests();

    // تهيئة قوائم الفئات والفروع
    categoryItems = [];
    selectedCategories = [];
    branchDropdownItems = [];
    selectedBranch = null;
  }

  // دالة لترتيب الفروع حسب الترتيب المطلوب: M ثم S ثم A
  List<String> _getOrderedBranches(List<String> branches) {
    // فرز الفروع حسب الترتيب المطلوب
    branches.sort((a, b) {
      // استخراج الحرف الأول من اسم الفرع
      String firstCharA = a.isNotEmpty ? a[0].toUpperCase() : '';
      String firstCharB = b.isNotEmpty ? b[0].toUpperCase() : '';

      // تحديد الأوزان حسب الترتيب المطلوب
      int getWeight(String char) {
        if (char == 'M') return 1;
        if (char == 'S') return 2;
        if (char == 'A') return 3;
        return 4; // أي حرف آخر يأتي في النهاية
      }

      int weightA = getWeight(firstCharA);
      int weightB = getWeight(firstCharB);

      if (weightA != weightB) {
        return weightA.compareTo(weightB);
      }

      // إذا كانت نفس المجموعة، نرتب أبجدياً
      return a.compareTo(b);
    });

    return branches;
  }

  Future<void> _loadProductionRequests() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      print("Fetching production data from: $apiUrl");
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(Duration(minutes: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data");

        final List<dynamic> productionData = data['data'] ?? [];
        print("Found ${productionData.length} production items");

        // تصفية البيانات للحصول فقط على العناصر التي لديها "isSend": false
        final List<dynamic> filteredProductionData = productionData.where((
          item,
        ) {
          return item['isSend'] == false;
        }).toList();

        print(
          "Found ${filteredProductionData.length} items with isSend: false",
        );

        // تجميع البيانات بشكل صحيح
        Map<String, ProductionItem> combinedItems = {};

        for (var item in filteredProductionData) {
          try {
            final branchName = item['branch']['name'] ?? 'غير معروف'.tr();
            final productKey =
                '${item['product']['name']}-${item['package']}-${item['mainProductOP']['name']}-$branchName';

            if (combinedItems.containsKey(productKey)) {
              combinedItems[productKey]!.requestedQty +=
                  (item['qty'] as num?)?.toDouble() ?? 0.0;
            } else {
              combinedItems[productKey] = ProductionItem(
                id: item['_id'] ?? '',
                productId: item['product']['_id'] ?? '',
                name: item['product']['name'] ?? 'غير معروف'.tr(),
                package: item['package']?.toString() ?? '0',
                quantity: 0.0,
                requestedQty: (item['qty'] as num?)?.toDouble() ?? 0.0,
                category: item['mainProductOP']['name'] ?? 'غير معروف'.tr(),
                branch: branchName,
                orderName: item['ordername'] ?? '',
                packageUnitname: item['packageUnit']?['name'] ?? "",
                isSend: item['isSend'] ?? false,
              );
            }
          } catch (e) {
            print("Error combining items: $e");
            continue;
          }
        }

        if (!mounted) return;
        setState(() {
          items = combinedItems.values.toList();
          print("Total combined items: ${items.length}");

          // تحديث قائمة الفئات للفلترة المتعددة
          final uniqueCategories = items
              .map((item) => item.category)
              .where((cat) => cat != null)
              .toSet()
              .toList();
          allCategories = uniqueCategories;

          // تحديث قائمة الفروع للفلترة مع تطبيق الترتيب المطلوب
          final uniqueBranches = items
              .map((item) => item.branch)
              .where((branch) => branch != null)
              .toSet()
              .toList();
          allBranches = _getOrderedBranches(uniqueBranches);

          // إنشاء عناصر الاختيار المتعدد للفئات
          categoryItems = allCategories
              .map((category) => MultiSelectItem<String>(category, category))
              .toList();

          // إنشاء عناصر Dropdown للفروع
          branchDropdownItems = [
            DropdownMenuItem<String>(
              value: null,
              child: Text('كل الفروع'.tr()),
            ),
            ...allBranches
                .map(
                  (branch) => DropdownMenuItem<String>(
                    value: branch,
                    child: Text(branch),
                  ),
                )
                .toList(),
          ];

          // تحديد جميع الفئات كاختيار افتراضي
          selectedCategories = List.from(allCategories);

          _filterItems();
        });

  
      } else {
        throw Exception('فشل في تحميل البيانات من السيرفر'.tr());
      }
    } catch (e) {
      print("Error loading production requests: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحميل البيانات'.tr()),
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

  void _filterItems() {
    if (!mounted) return;

    setState(() {
      List<ProductionItem> tempItems = List.from(items);

      // تطبيق فلتر الفئات
      if (selectedCategories.isNotEmpty &&
          selectedCategories.length != allCategories.length) {
        tempItems = tempItems
            .where((item) => selectedCategories.contains(item.category))
            .toList();
      }

      // تطبيق فلتر الفروع (Dropdown)
      if (selectedBranch != null) {
        tempItems = tempItems
            .where((item) => item.branch == selectedBranch)
            .toList();
      }

      filteredItems = tempItems;
    });
  }

  // دالة جديدة لتنظيم البيانات حسب الفئة الرئيسية والمنتجات
  Map<String, List<ProductionItem>> _organizeItemsByMainCategory() {
    Map<String, List<ProductionItem>> organizedData = {};

    for (var item in filteredItems) {
      if (!organizedData.containsKey(item.category)) {
        organizedData[item.category] = [];
      }
      organizedData[item.category]!.add(item);
    }

    // ترتيب المنتجات داخل كل فئة أبجدياً
    organizedData.forEach((category, products) {
      products.sort((a, b) => a.name.compareTo(b.name));
    });

    return organizedData;
  }

  // دالة جديدة لتنظيم البيانات حسب الفروع والمنتجات
  Map<String, Map<String, ProductionItem>> _organizeItemsByBranchAndProduct() {
    Map<String, Map<String, ProductionItem>> organizedData = {};

    for (var item in filteredItems) {
      // إضافة الفرع إذا لم يكن موجوداً
      if (!organizedData.containsKey(item.branch)) {
        organizedData[item.branch] = {};
      }

      // إضافة/تحديث المنتج تحت هذا الفرع
      if (!organizedData[item.branch]!.containsKey(item.name)) {
        organizedData[item.branch]![item.name] = ProductionItem(
          id: item.id,
          productId: item.productId,
          name: item.name,
          package: item.package,
          quantity: 0.0,
          requestedQty: 0.0,
          category: item.category,
          branch: item.branch,
          orderName: item.orderName,
          packageUnitname: item.packageUnitname,
          isSend: item.isSend,
        );
      }

      organizedData[item.branch]![item.name]!.requestedQty += item.requestedQty;
    }

    return organizedData;
  }

  // دالة جديدة للحصول على جميع المنتجات الفريدة مع بيانات العبوة
  List<ProductionItem> _getAllUniqueProducts() {
    Map<String, ProductionItem> uniqueProducts = {};
    for (var item in filteredItems) {
      if (!uniqueProducts.containsKey(item.name)) {
        uniqueProducts[item.name] = ProductionItem(
          id: item.id,
          productId: item.productId,
          name: item.name,
          package: item.package,
          quantity: 0.0,
          requestedQty: 0.0,
          category: item.category,
          branch: item.branch,
          orderName: item.orderName,
          packageUnitname: item.packageUnitname,
          isSend: item.isSend,
        );
      }
    }
    return uniqueProducts.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // دالة جديدة لحساب الإجمالي لكل منتج عبر جميع الفروع
  double _calculateTotalForProduct(
    String productName,
    Map<String, Map<String, ProductionItem>> organizedData,
  ) {
    double total = 0.0;
    for (var branchData in organizedData.values) {
      if (branchData.containsKey(productName)) {
        total += branchData[productName]!.requestedQty;
      }
    }
    return total;
  }

  // دالة جديدة لحساب إجمالي الفرع
  double _calculateBranchTotal(
    String branchName,
    Map<String, Map<String, ProductionItem>> organizedData,
  ) {
    if (!organizedData.containsKey(branchName)) return 0.0;

    double total = 0.0;
    for (var item in organizedData[branchName]!.values) {
      total += item.requestedQty;
    }
    return total;
  }

  // دالة جديدة لحساب الإجمالي الكلي
  double _calculateGrandTotal(
    Map<String, Map<String, ProductionItem>> organizedData,
  ) {
    double total = 0.0;
    for (var branchData in organizedData.values) {
      for (var item in branchData.values) {
        total += item.requestedQty;
      }
    }
    return total;
  }

  // لفئات الرئيسية
  Widget _buildCategoryBasedView() {
    final organizedData = _organizeItemsByMainCategory();
    final branches = _getOrderedBranches(allBranches);

    if (organizedData.isEmpty) {
      return Center(child: Text("لا توجد نتائج للعرض".tr()));
    }

    return ListView.builder(
      itemCount: organizedData.length,
      itemBuilder: (context, categoryIndex) {
        final category = organizedData.keys.elementAt(categoryIndex);
        final categoryProducts = organizedData[category]!;

        return _buildCategorySection(category, categoryProducts, branches);
      },
    );
  }

  // بناء قسم الفئة الرئيسية
  Widget _buildCategorySection(
    String category,
    List<ProductionItem> products,
    List<String> branches,
  ) {
    final organizedData = _organizeItemsByBranchAndProductForCategory(products);

    return Card(
      elevation: 2,
      child: Column(
        children: [
          // رأس الفئة الرئيسية
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 5),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(),
            ),
            child: Text(
              category,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // جدول المنتجات
          _buildProductsTable(organizedData, branches),
        ],
      ),
    );
  }

  // تنظيم البيانات حسب الفروع والمنتجات لفئة معينة
  Map<String, Map<String, ProductionItem>>
  _organizeItemsByBranchAndProductForCategory(List<ProductionItem> products) {
    Map<String, Map<String, ProductionItem>> organizedData = {};

    for (var item in products) {
      if (!organizedData.containsKey(item.branch)) {
        organizedData[item.branch] = {};
      }

      if (!organizedData[item.branch]!.containsKey(item.name)) {
        organizedData[item.branch]![item.name] = ProductionItem(
          id: item.id,
          productId: item.productId,
          name: item.name,
          package: item.package,
          quantity: 0.0,
          requestedQty: 0.0,
          category: item.category,
          branch: item.branch,
          orderName: item.orderName,
          packageUnitname: item.packageUnitname,
          isSend: item.isSend,
        );
      }

      organizedData[item.branch]![item.name]!.requestedQty += item.requestedQty;
    }

    return organizedData;
  }

  // بناء جدول المنتجات
  Widget _buildProductsTable(
    Map<String, Map<String, ProductionItem>> organizedData,
    List<String> branches,
  ) {
    final uniqueProducts = _getUniqueProductsFromOrganizedData(organizedData);

    if (uniqueProducts.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text('لا توجد منتجات في هذه الفئة'.tr()),
      );
    }

    return Column(
      children: [
        // محتوى الجدول
        ...uniqueProducts
            .map(
              (product) => _buildProductRow(product, branches, organizedData),
            )
            .toList(),
      ],
    );
  }

  // الحصول على المنتجات الفريدة من البيانات المنظمة
  List<ProductionItem> _getUniqueProductsFromOrganizedData(
    Map<String, Map<String, ProductionItem>> organizedData,
  ) {
    Set<String> productNames = {};
    List<ProductionItem> uniqueProducts = [];

    for (var branchData in organizedData.values) {
      for (var product in branchData.values) {
        if (!productNames.contains(product.name)) {
          productNames.add(product.name);
          uniqueProducts.add(product);
        }
      }
    }

    uniqueProducts.sort((a, b) => a.name.compareTo(b.name));
    return uniqueProducts;
  }

  // بناء رأس الجدول
  Widget _buildTableHeader(List<String> branches) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32;
    final productColumnWidth = availableWidth * 0.4;
    final branchColumnWidth =
        (availableWidth - productColumnWidth) / (branches.length + 1);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: secondaryColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: productColumnWidth,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: secondaryColor.withOpacity(0.3)),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'المنتجات'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  '(الحجم / الوحدة)'.tr(),
                  style: GoogleFonts.cairo(fontSize: 10, color: lightTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // رؤوس الفروع
          ...branches
              .map(
                (branch) => Container(
                  width: branchColumnWidth,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: secondaryColor.withOpacity(0.3)),
                    ),
                  ),
                  child: Text(
                    _getAbbreviatedBranchName(branch),
                    style: GoogleFonts.cairo(
                      fontSize: _getBranchFontSize(branch),
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),

          // رأس عمود الإجمالي
          Container(
            width: branchColumnWidth,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              border: Border(
                right: BorderSide(color: secondaryColor.withOpacity(0.3)),
              ),
            ),
            child: Text(
              'الإجمالي'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // دالة لاختصار اسم الفرع
  String _getAbbreviatedBranchName(String branch) {
    if (branch.length <= 8) return branch;

    // محاولة تقسيم الاسم إلى كلمات وأخذ الحروف الأولى
    final words = branch.split(' ');
    if (words.length > 1) {
      return words.map((word) => word.isNotEmpty ? word[0] : '').join();
    }

    // إذا كان كلمة واحدة، نأخذ أول 6 أحرف
    return branch.substring(0, 6);
  }

  // دالة لتحديد حجم الخط بناءً على طول النص
  double _getBranchFontSize(String branch) {
    final length = branch.length;
    if (length <= 4) return 12;
    if (length <= 6) return 11;
    if (length <= 8) return 10;
    return 9;
  }

  // بناء صف منتج واحد
  Widget _buildProductRow(
    ProductionItem product,
    List<String> branches,
    Map<String, Map<String, ProductionItem>> organizedData,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32;
    final productColumnWidth = availableWidth * 0.4;
    final branchColumnWidth =
        (availableWidth - productColumnWidth) / (branches.length + 1);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: secondaryColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // اسم المنتج ومعلومات العبوة
          Container(
            width: productColumnWidth,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: secondaryColor.withOpacity(0.1)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  textAlign: TextAlign.center, // ✅ يخلي النص في النص

                  maxLines: 4,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '${product.package} ${product.packageUnitname}',
                  style: GoogleFonts.cairo(fontSize: 10, color: lightTextColor),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),

          // بيانات الفروع لهذا المنتج
          ...branches
              .map(
                (branch) => Container(
                  width: branchColumnWidth,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: secondaryColor.withOpacity(0.1)),
                    ),
                  ),
                  child: Text(
                    organizedData.containsKey(branch) &&
                            organizedData[branch]!.containsKey(product.name)
                        ? _formatNumber(
                            organizedData[branch]![product.name]!.requestedQty,
                          )
                        : '-',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              .toList(),

          // الإجمالي للمنتج
          Container(
            width: branchColumnWidth,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(.1),
              border: Border(
                right: BorderSide(color: secondaryColor.withOpacity(0.1)),
              ),
            ),
            child: Text(
              _formatNumber(
                _calculateTotalForProduct(product.name, organizedData),
              ),
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // دالة لعرض الأرقام كما هي بدون تقريب
  String _formatNumber(double number) {
    // تحويل الرقم إلى سلسلة نصية بدون تقريب
    String numberString = number.toString();

    // إذا كان الرقم يحتوي على .0 في النهاية، نزيلها
    if (numberString.endsWith('.0')) {
      return numberString.substring(0, numberString.length - 2);
    }

    // إذا كان الرقم يحتوي على أصفار زائدة بعد الفاصلة، نزيلها
    if (numberString.contains('.')) {
      numberString = numberString.replaceAll(RegExp(r'0+$'), '');
      if (numberString.endsWith('.')) {
        numberString = numberString.substring(0, numberString.length - 1);
      }
    }

    return numberString;
  }

  Widget _buildProductionPage() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // فلتر الفئات والفروع
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                // فلتر الفئات
                Expanded(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text(
                            "الفئة".tr() + ":",
                            style: GoogleFonts.cairo(
                              fontSize: isVerySmallScreen
                                  ? 12
                                  : isSmallScreen
                                  ? 14
                                  : 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: secondaryColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: MultiSelectDialogField(
                                items: categoryItems,
                                title: Text('اختر الفئات'.tr()),
                                selectedColor: primaryColor,
                                decoration: BoxDecoration(
                                  color: backgroundColor.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                buttonIcon: Icon(
                                  Icons.category,
                                  color: primaryColor,
                                ),
                                buttonText: Text(
                                  selectedCategories.isEmpty
                                      ? 'كل الفئات'.tr()
                                      : '${selectedCategories.length} ${"الفئة".tr()}',
                                  style: GoogleFonts.cairo(
                                    fontSize: isVerySmallScreen
                                        ? 9
                                        : isSmallScreen
                                        ? 11
                                        : 14,
                                    color: textColor,
                                  ),
                                ),
                                onConfirm: (results) {
                                  setState(() {
                                    selectedCategories = results.cast<String>();
                                    _filterItems();
                                  });
                                },
                                chipDisplay: MultiSelectChipDisplay.none(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // فلتر الفروع
                Expanded(
                  child: Container(
                    height: 68.5,
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(4.9),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Text(
                                'الفرع:'.tr(),
                                style: GoogleFonts.cairo(
                                  fontSize: isVerySmallScreen
                                      ? 12
                                      : isSmallScreen
                                      ? 14
                                      : 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: secondaryColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: DropdownButton<String>(
                                      value: selectedBranch,
                                      items: branchDropdownItems,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedBranch = newValue;
                                          _filterItems();
                                        });
                                      },
                                      underline: Container(),
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: primaryColor,
                                      ),
                                      isExpanded: true,
                                      style: GoogleFonts.cairo(
                                        fontSize: isVerySmallScreen
                                            ? 12
                                            : isSmallScreen
                                            ? 14
                                            : 16,
                                        color: textColor,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // حالة التحميل
          if (isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  strokeWidth: 4,
                ),
              ),
            )
          // حالة عدم وجود بيانات
          else if (filteredItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.production_quantity_limits,
                      size: isVerySmallScreen
                          ? 55
                          : isSmallScreen
                          ? 65
                          : 75,
                      color: secondaryColor,
                    ),
                    SizedBox(
                      height: isVerySmallScreen
                          ? 12
                          : isSmallScreen
                          ? 16
                          : 20,
                    ),
                    if (items.isEmpty) ...[
                      Text(
                        'لا توجد طلبات في هذا القسم'.tr(),
                        style: GoogleFonts.cairo(
                          fontSize: isVerySmallScreen
                              ? 16
                              : isSmallScreen
                              ? 18
                              : 20,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            // عرض الجدول الجديد حسب الفئات
            _buildTableHeader(allBranches),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildCategoryBasedView(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        toolbarHeight: 27,
        title: Text('توريد'.tr(), style: GoogleFonts.cairo(fontSize: 16)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildProductionPage(),
    );
  }
}

class ProductionItem {
  String id;
  String productId;
  String name;
  String package;
  String packageUnitname;
  double quantity;
  double requestedQty;
  String category;
  String branch;
  String orderName;
  bool isApproved;
  bool isSend;

  ProductionItem({
    required this.id,
    required this.productId,
    required this.name,
    required String package,
    String? packageUnitname,
    required this.quantity,
    required this.requestedQty,
    required this.category,
    required this.branch,
    required this.orderName,
    this.isApproved = false,
    required this.isSend,
  }) : package = _sanitizePackage(package), // استخدام دالة مساعدة
       packageUnitname = packageUnitname ?? "";

  static String _sanitizePackage(String package) {
    if (package == "لم يحدد" || package == "undefined" || package.isEmpty) {
      return "";
    }
    return package;
  }
}
