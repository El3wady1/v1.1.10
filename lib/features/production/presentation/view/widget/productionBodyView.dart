import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/features/production/presentation/view/widget/production_Supply.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class ProductionBodyView extends StatefulWidget {
  final String role;
  ProductionBodyView({required this.role});

  @override
  _ProductionBodyViewState createState() => _ProductionBodyViewState();
}

class _ProductionBodyViewState extends State<ProductionBodyView> {
  int _currentIndex = 0;
  List<ProductionItem> items = [];
  List<ProductionItem> filteredItems = [];
  List<TextEditingController> quantityControllers = [];
  List<AcceptedItem> acceptedItems = [];
  bool isLoading = false;
  String apiUrl =
      "${Apiendpoints.baseUrl}${Apiendpoints.orderProduction.getOrderPof2Days}";
  String submitUrl =
      "${Apiendpoints.baseUrl}${Apiendpoints.production.request}";
  String acceptedUrl =
      "${Apiendpoints.baseUrl}${Apiendpoints.production.getPending}";
  String updateQtyUrl =
      "${Apiendpoints.baseUrl}${Apiendpoints.production.updateQty}";
  String approveUrl =
      "${Apiendpoints.baseUrl}${Apiendpoints.production.approve}";
  String refuseUrl =
      "${Apiendpoints.baseUrl}${Apiendpoints.production.refusePendingRequest}";


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
  String? selectedBranch; // null يعني "الكل"
  List<DropdownMenuItem<String>> branchDropdownItems = [];

  @override
 
void initState() {
  super.initState();
  
  // تأخير تحميل البيانات قليلاً لضمان تحميل الواجهة أولاً
  Future.delayed(Duration(milliseconds: 100), () {
    if (mounted) {
      _loadProductionRequests();
      if (widget.role == "admin") {
        _loadAcceptedRequests();
      }
    }
  });

  // تهيئة قوائم الفئات والفروع
  categoryItems = [];
  selectedCategories = [];
  branchDropdownItems = [];
  selectedBranch = null;
}

  @override
  void dispose() {
    for (var controller in quantityControllers) {
      controller.dispose();
    }
    super.dispose();
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

      // تحديث حالة التحميل أولاً
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      // ثم تحديث البيانات بعد فترة قصيرة لضمان تحديث الواجهة
      if (mounted) {
        await Future.delayed(Duration(milliseconds: 100));
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

          // تحديث قائمة الفروع للفلترة
          final uniqueBranches = items
              .map((item) => item.branch)
              .where((branch) => branch != null)
              .toSet()
              .toList();
          allBranches = uniqueBranches;

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

          quantityControllers = items
              .map(
                (item) =>
                    TextEditingController(text: _formatNumber(item.quantity)),
              )
              .toList();
          _filterItems();
        });
      }
    
    } else {
      throw Exception('فشل في تحميل البيانات من السيرفر'.tr());
    }
  } catch (e) {
    print("Error loading production requests: $e");
    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في تحميل البيانات'.tr()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
} 

Widget _buildLoadingIndicator() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          strokeWidth: 4,
        ),
        SizedBox(height: 16),
        Text(
          'جاري تحميل البيانات...'.tr(),
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
 Future<void> _loadAcceptedRequests() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final response = await http
          .get(Uri.parse(acceptedUrl))
          .timeout(Duration(minutes: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> acceptedData = data['data'] ?? [];

        List<AcceptedItem> loadedItems = [];

        for (var item in acceptedData) {
          try {
            // Handle the case where product might be a list or a single object
            dynamic productData = item['product'];
            if (productData is List && productData.isNotEmpty) {
              productData = productData[0];
            }

            loadedItems.add(
              AcceptedItem(
                id: item['_id'] ?? '',
                productId: productData['_id'] ?? '',
                name: productData['name'] ?? 'غير معروف',
                package: productData['packSize']?.toString() ?? '0',
                quantity: (item['qty'] as num?)?.toDouble() ?? 0.0,
                status: item['status'] ?? 'pending',
                date: item['createdAt'] ?? '',
                packageUnitname: productData['packageUnit']?['name'] ?? "",
              ),
            );
          } catch (e) {
            print('Error parsing accepted item: $e');
            continue;
          }
        }

        if (!mounted) return;
        setState(() {
          acceptedItems = loadedItems;
        });
      } else {
        throw Exception('فشل في تحميل الطلبات المقبولة'.tr());
      }
    } catch (e) {
      print('Error loading accepted requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحميل الطلبات المقبولة'.tr()),
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

  Future<void> _updateQuantity(String id, double newQuantity) async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final response = await http
          .put(
            Uri.parse('$updateQtyUrl$id'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'qty': newQuantity}),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم تحديث الكمية بنجاح".tr()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadAcceptedRequests();
      } else {
        throw Exception('فشل في تحديث الكمية'.tr());
      }
    } catch (e) {
      print('Error updating quantity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحديث الكمية'.tr()),
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

  Future<void> _approveRequests(List<String> requestIds) async {
    if (!mounted || requestIds.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse(approveUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({"requestIds": requestIds}),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم اعتماد الطلبات بنجاح".tr()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadAcceptedRequests();
      } else {
        throw Exception('فشل في اعتماد الطلبات'.tr());
      }
    } catch (e) {
      print('Error approving requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في اعتماد الطلبات'.tr()),
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

  Future<void> _refuseRequests(List<String> requestIds) async {
    if (!mounted || requestIds.isEmpty) return;

    setState(() => isLoading = true);

    try {
      // Assuming your API supports bulk refusal
      for (String id in requestIds) {
        final response = await http
            .delete(
              Uri.parse('$refuseUrl$id'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(Duration(seconds: 30));

        if (response.statusCode != 200) {
          throw Exception('فشل في رفض الطلب'.tr());
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم رفض الطلبات بنجاح".tr()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadAcceptedRequests();
    } catch (e) {
      print('Error refusing requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في رفض الطلبات'.tr()),
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

  Future<void> _refuseRequest(String requestId) async {
    await _refuseRequests([requestId]);
  }
void _filterItems() {
  if (!mounted) return;

  // استخدام Future.microtask لضمان تحديث الواجهة بعد اكتمال الإطار الحالي
  Future.microtask(() {
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
      
      // طباعة معلومات التصفية للمساعدة في التصحيح
      print("Filtered items: ${filteredItems.length}");
      print("Selected categories: ${selectedCategories.length}");
      print("Selected branch: $selectedBranch");
    });
  });
} // دالة جديدة لتنظيم البيانات حسب الفئة الرئيسية والمنتجات
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

  // دالة جديدة للحصول على جميع أسماء المنتجات الفريدة مع بيانات العبوة
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

  // تم تعديل الدالة لعرض الأرقام كما هي بدون تقريب
  String _formatNumber(double number) {
    // عرض الرقم كما هو بدون أي تقريب أو تعديل
    String numberStr = number.toString();

    // إذا كان الرقم يحتوي على .0 في النهاية، نزيلها للتبسيط
    if (numberStr.contains('.') && numberStr.endsWith('0')) {
      numberStr = numberStr.replaceAll(RegExp(r'\.0+$'), '');
    }

    return numberStr;
  }

  // دالة لترتيب الفروع حسب الترتيب المطلوب: M أولاً، ثم S، ثم A
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

 Widget _buildCategoryBasedView() {
  final organizedData = _organizeItemsByMainCategory();
  final branches = _getOrderedBranches(allBranches);

  if (organizedData.isEmpty) {
    return Center(child: Text("لا توجد نتائج للعرض".tr()));
  }

  return RefreshIndicator(
    backgroundColor: backgroundColor,
    color: primaryColor,
    onRefresh: () async {
      await _loadProductionRequests();
    },
    child: ListView.builder(
      itemCount: organizedData.length,
      itemBuilder: (context, categoryIndex) {
        final category = organizedData.keys.elementAt(categoryIndex);
        final categoryProducts = organizedData[category]!;

        return _buildCategorySection(category, categoryProducts, branches);
      },
    ),
  );
}
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
        // رأس الجدول
        _buildTableHeader(branches),

        // محتوى الجدول
        ...uniqueProducts
            .map(
              (product) => _buildProductRow(product, branches, organizedData),
            )
            .toList(),

        // صف الإجمالي
        // _buildTotalRow(uniqueProducts, organizedData, branches),
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
    if (length <= 4) return 11;
    if (length <= 6) return 10;
    if (length <= 8) return 9;
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

  // بناء صف الإجمالي
  Widget _buildTotalRow(
    List<ProductionItem> uniqueProducts,
    Map<String, Map<String, ProductionItem>> organizedData,
    List<String> branches,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32;
    final productColumnWidth = availableWidth * 0.4;
    final branchColumnWidth =
        (availableWidth - productColumnWidth) / (branches.length + 1);

    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        border: Border(top: BorderSide(color: secondaryColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          // خلية "الإجمالي"
          Container(
            width: productColumnWidth,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: secondaryColor.withOpacity(0.1)),
              ),
            ),
            child: Text(
              'الإجمالي'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // إجمالي كل فرع
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
                    _formatNumber(_calculateBranchTotal(branch, organizedData)),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              .toList(),

          // الإجمالي الكلي
          Container(
            width: branchColumnWidth,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: secondaryColor.withOpacity(0.1)),
              ),
            ),
            child: Text(
              _formatNumber(_calculateGrandTotal(organizedData)),
              style: GoogleFonts.cairo(
                fontSize: 12,
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

  Widget _buildAcceptedItemRow(AcceptedItem item, int index) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;
    final isLargeScreen = screenSize.width > 600;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isVerySmallScreen
              ? 10
              : isSmallScreen
              ? 12
              : 14,
          horizontal: isVerySmallScreen
              ? 8
              : isSmallScreen
              ? 12
              : 16,
        ),
        child: Row(
          children: [
            // اسم المنتج ومعلومات العبوة
            Expanded(
              flex: isLargeScreen ? 4 : 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.name,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 14
                          : isSmallScreen
                          ? 16
                          : 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${item.package} ${item.packageUnitname}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 12
                          : isSmallScreen
                          ? 13
                          : 14,
                      color: lightTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // الكمية مع إمكانية التعديل
            Container(
              width: isLargeScreen
                  ? 70
                  : (isVerySmallScreen
                        ? 50
                        : isSmallScreen
                        ? 60
                        : 70),
              alignment: Alignment.center,
              child: InkWell(
                onTap: () => _showQuantityDialog(item),
                child: Text(
                  _formatNumber(item.quantity),
                  style: GoogleFonts.cairo(
                    fontSize: isVerySmallScreen
                        ? 14
                        : isSmallScreen
                        ? 16
                        : 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    decoration: widget.role == "admin"
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ),
            ),

            // الحالة
            Expanded(
              flex: isLargeScreen ? 3 : 2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 6 : 8,
                    vertical: isVerySmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(item.status),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 12
                          : isSmallScreen
                          ? 13
                          : 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Actions for admin (approve/refuse)
            if (widget.role == "admin" && item.status == "pending")
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveRequests([item.id]),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => _showRefuseDialog(item.id),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(AcceptedItem item) {
    if (widget.role != "admin") return;

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    TextEditingController qtyController = TextEditingController(
      text: _formatNumber(item.quantity),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(
            isVerySmallScreen
                ? 14
                : isSmallScreen
                ? 18
                : 22,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Text(
                  'تعديل الكمية'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: isVerySmallScreen
                        ? 18
                        : isSmallScreen
                        ? 20
                        : 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              SizedBox(
                height: isVerySmallScreen
                    ? 12
                    : isSmallScreen
                    ? 16
                    : 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 16
                          : isSmallScreen
                          ? 17
                          : 18,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${item.package} ${item.packageUnitname}',
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen
                          ? 14
                          : isSmallScreen
                          ? 15
                          : 16,
                      color: lightTextColor,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: isVerySmallScreen
                    ? 8
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen
                      ? 16
                      : isSmallScreen
                      ? 18
                      : 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  labelText: 'الكمية الجديدة'.tr(),
                  labelStyle: GoogleFonts.cairo(color: lightTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: secondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                ),
              ),
              SizedBox(
                height: isVerySmallScreen
                    ? 16
                    : isSmallScreen
                    ? 20
                    : 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallScreen
                            ? 14
                            : isSmallScreen
                            ? 18
                            : 22,
                        vertical: isVerySmallScreen
                            ? 10
                            : isSmallScreen
                            ? 12
                            : 14,
                      ),
                    ),
                    child: Text(
                      'إلغاء'.tr(),
                      style: GoogleFonts.cairo(
                        fontSize: isVerySmallScreen
                            ? 16
                            : isSmallScreen
                            ? 17
                            : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(
                    width: isVerySmallScreen
                        ? 10
                        : isSmallScreen
                        ? 14
                        : 18,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallScreen
                            ? 18
                            : isSmallScreen
                            ? 22
                            : 26,
                        vertical: isVerySmallScreen
                            ? 10
                            : isSmallScreen
                            ? 12
                            : 14,
                      ),
                    ),
                    child: Text(
                      'حفظ'.tr(),
                      style: GoogleFonts.cairo(
                        fontSize: isVerySmallScreen
                            ? 16
                            : isSmallScreen
                            ? 17
                            : 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      final newQty =
                          double.tryParse(qtyController.text) ?? item.quantity;
                      Navigator.pop(context);
                      _updateQuantity(item.id, newQty);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRefuseDialog(String requestId) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'رفض الطلب'.tr(),
          style: GoogleFonts.cairo(
            fontSize: isVerySmallScreen
                ? 18
                : isSmallScreen
                ? 20
                : 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        content: Text(
          'هل أنت متأكد من رفض هذا الطلب؟'.tr(),
          style: GoogleFonts.cairo(
            fontSize: isVerySmallScreen
                ? 16
                : isSmallScreen
                ? 17
                : 18,
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'إلغاء'.tr(),
              style: GoogleFonts.cairo(
                fontSize: isVerySmallScreen
                    ? 16
                    : isSmallScreen
                    ? 17
                    : 18,
                color: primaryColor,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'رفض'.tr(),
              style: GoogleFonts.cairo(
                fontSize: isVerySmallScreen
                    ? 16
                    : isSmallScreen
                    ? 17
                    : 18,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _refuseRequest(requestId);
            },
          ),
        ],
      ),
    );
  }

  void _showBulkActionDialog(bool isApprove) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    final pendingItems = acceptedItems
        .where((item) => item.status == "pending")
        .toList();
    if (pendingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا توجد طلبات قيد الانتظار'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isApprove ? 'اعتماد الكل'.tr() : 'رفض الكل'.tr(),
          style: GoogleFonts.cairo(
            fontSize: isVerySmallScreen
                ? 18
                : isSmallScreen
                ? 20
                : 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        content: Text(
          isApprove
              ? 'هل أنت متأكد من اعتماد جميع الطلبات القيد الانتظار؟'.tr()
              : 'هل أنت متأكد من رفض جميع الطلبات القيد الانتظار؟'.tr(),
          style: GoogleFonts.cairo(
            fontSize: isVerySmallScreen
                ? 16
                : isSmallScreen
                ? 17
                : 18,
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'إلغاء'.tr(),
              style: GoogleFonts.cairo(
                fontSize: isVerySmallScreen
                    ? 16
                    : isSmallScreen
                    ? 17
                    : 18,
                color: primaryColor,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isApprove ? 'اعتماد الكل'.tr() : 'رفض الكل'.tr(),
              style: GoogleFonts.cairo(
                fontSize: isVerySmallScreen
                    ? 16
                    : isSmallScreen
                    ? 17
                    : 18,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              final pendingIds = pendingItems.map((item) => item.id).toList();
              if (isApprove) {
                _approveRequests(pendingIds);
              } else {
                _refuseRequests(pendingIds);
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار'.tr();
      case 'approved':
        return 'مقبول'.tr();
      case 'rejected':
        return 'مرفوض'.tr();
      default:
        return 'غير معروف'.tr();
    }
  }

  Widget _buildBulkActionButtons() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

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
            child: ElevatedButton.icon(
              icon: Icon(Icons.check_circle, size: isVerySmallScreen ? 18 : 20),
              label: Text(
                'اعتماد الكل'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen
                      ? 14
                      : isSmallScreen
                      ? 16
                      : 18,
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(
                  vertical: isVerySmallScreen
                      ? 12
                      : isSmallScreen
                      ? 14
                      : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _showBulkActionDialog(true),
            ),
          ),
          SizedBox(
            width: isVerySmallScreen
                ? 8
                : isSmallScreen
                ? 12
                : 16,
          ),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.cancel, size: isVerySmallScreen ? 18 : 20),
              label: Text(
                'رفض الكل'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen
                      ? 14
                      : isSmallScreen
                      ? 16
                      : 18,
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(
                  vertical: isVerySmallScreen
                      ? 12
                      : isSmallScreen
                      ? 14
                      : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _showBulkActionDialog(false),
            ),
          ),
        ],
      ),
    );
  }

  bool isloading = false;

  // دالة لبناء محتوى كل صفحة
  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0: // الانتاج اليومي
        return _buildProductionPage();
      case 1: // التوريد (للمشرف فقط)
        return Production_Supply(role: widget.role);
      default:
        return _buildProductionPage();
    }
  }

Widget _buildNoDataWidget() {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 400;
  final isVerySmallScreen = screenSize.width < 350;

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.production_quantity_limits,
          size: isVerySmallScreen ? 55 : isSmallScreen ? 65 : 75,
          color: secondaryColor,
        ),
        SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 20),
        Text(
          'لا توجد طلبات إنتاج حالياً'.tr(),
          style: GoogleFonts.cairo(
            fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'سيتم عرض الطلبات هنا عند توفرها'.tr(),
          style: GoogleFonts.cairo(
            fontSize: isVerySmallScreen ? 14 : isSmallScreen ? 15 : 16,
            color: lightTextColor,
          ),
        ),
      ],
    ),
  );
}

Widget _buildNoFilteredDataWidget() {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 400;
  final isVerySmallScreen = screenSize.width < 350;

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off,
          size: isVerySmallScreen ? 55 : isSmallScreen ? 65 : 75,
          color: secondaryColor,
        ),
        SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 20),
        Text(
          'لا توجد نتائج مطابقة للبحث'.tr(),
          style: GoogleFonts.cairo(
            fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'جرب تغيير فلتر الفئات أو الفروع'.tr(),
          style: GoogleFonts.cairo(
            fontSize: isVerySmallScreen ? 14 : isSmallScreen ? 15 : 16,
            color: lightTextColor,
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            setState(() {
              selectedCategories = List.from(allCategories);
              selectedBranch = null;
              _filterItems();
            });
          },
          child: Text(
            'إعادة تعيين الفلاتر'.tr(),
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
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
            child: _buildLoadingIndicator(),
          )
        // حالة عدم وجود بيانات
        else if (filteredItems.isEmpty && items.isEmpty)
          Expanded(
            child: _buildNoDataWidget(),
          )
        else if (filteredItems.isEmpty && items.isNotEmpty)
          Expanded(
            child: _buildNoFilteredDataWidget(),
          )
        else
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildCategoryBasedView(),
            ),
          ),
      ],
    ),
  );
}  Widget _buildApprovel_Production() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // أزرار الإجراءات الجماعية
          if (acceptedItems.any((item) => item.status == "pending"))
            _buildBulkActionButtons(),

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
          else if (acceptedItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_alt,
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
                    Text(
                      'لا توجد طلبات معتمدة'.tr(),
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
                ),
              ),
            )
          else
            // قائمة العناصر
            Expanded(
              child: ListView.builder(
                itemCount: acceptedItems.length,
                itemBuilder: (context, index) {
                  return _buildAcceptedItemRow(acceptedItems[index], index);
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    // تحديد عناصر NavigationBar بناءً على دور المستخدم
    final List<NavigationDestination> navigationItems = [
      NavigationDestination(
        icon: Icon(Icons.production_quantity_limits),
        label: 'الانتاج اليومي'.tr(),
      ),
      // if (widget.role == "admin")
      NavigationDestination(
        icon: Icon(Icons.local_shipping),
        label: 'توريد'.tr(),
      ),
    ];

    return ModalProgressHUD(
      inAsyncCall: isloading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "الانتاج".tr(),
            style: GoogleFonts.cairo(
              fontSize: isVerySmallScreen
                  ? 17
                  : isSmallScreen
                  ? 19
                  : 21,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          toolbarHeight: 45,
          backgroundColor: primaryColor,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: _buildCurrentPage(),
        bottomNavigationBar: NavigationBar(
          height: 71,
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.cairo(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: navigationItems,
          backgroundColor: Colors.white,
          indicatorColor: primaryColor.withOpacity(0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    if (!mounted) return;

    bool allApproved = filteredItems.every((item) => item.isApproved);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.width < 350;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(
            isVerySmallScreen
                ? 14
                : isSmallScreen
                ? 18
                : 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'تأكيد الإنتاج'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: isVerySmallScreen
                        ? 18
                        : isSmallScreen
                        ? 20
                        : 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              SizedBox(
                height: isVerySmallScreen
                    ? 12
                    : isSmallScreen
                    ? 16
                    : 20,
              ),
              Text(
                'هل أنت متأكد من الكميات المنتجة؟'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen
                      ? 16
                      : isSmallScreen
                      ? 17
                      : 18,
                  color: textColor,
                ),
              ),
              if (!allApproved) ...[
                SizedBox(
                  height: isVerySmallScreen
                      ? 8
                      : isSmallScreen
                      ? 12
                      : 16,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: accentColor,
                      size: isVerySmallScreen
                          ? 20
                          : isSmallScreen
                          ? 22
                          : 24,
                    ),
                    SizedBox(
                      width: isVerySmallScreen
                          ? 6
                          : isSmallScreen
                          ? 8
                          : 10,
                    ),
                    Text(
                      'بعض الأصناف غير معتمدة'.tr(),
                      style: GoogleFonts.cairo(
                        fontSize: isVerySmallScreen
                            ? 14
                            : isSmallScreen
                            ? 15
                            : 16,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(
                height: isVerySmallScreen
                    ? 12
                    : isSmallScreen
                    ? 16
                    : 20,
              ),
              Row(
                children: [
                  Icon(
                    Icons.inventory,
                    color: primaryColor,
                    size: isVerySmallScreen
                        ? 20
                        : isSmallScreen
                        ? 22
                        : 24,
                  ),
                  SizedBox(
                    width: isVerySmallScreen
                        ? 6
                        : isSmallScreen
                        ? 8
                        : 10,
                  ),
                  Flexible(
                    child: Text(
                      'سيتم إضافة الكميات إلى قائمة الانتظار الي حين اعتماد المشرف'
                          .tr(),
                      style: GoogleFonts.cairo(
                        fontSize: isVerySmallScreen
                            ? 14
                            : isSmallScreen
                            ? 15
                            : 16,
                        color: lightTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: isVerySmallScreen
                    ? 16
                    : isSmallScreen
                    ? 20
                    : 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallScreen
                            ? 14
                            : isSmallScreen
                            ? 18
                            : 22,
                        vertical: isVerySmallScreen
                            ? 10
                            : isSmallScreen
                            ? 12
                            : 14,
                      ),
                    ),
                    child: Text(
                      'إلغاء'.tr(),
                      style: GoogleFonts.cairo(
                        fontSize: isVerySmallScreen
                            ? 16
                            : isSmallScreen
                            ? 17
                            : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(
                    width: isVerySmallScreen
                        ? 10
                        : isSmallScreen
                        ? 14
                        : 18,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallScreen
                            ? 18
                            : isSmallScreen
                            ? 22
                            : 26,
                        vertical: isVerySmallScreen
                            ? 10
                            : isSmallScreen
                            ? 12
                            : 14,
                      ),
                    ),
                    child: Text(
                      'تأكيد'.tr(),
                      style: GoogleFonts.cairo(
                        fontSize: isVerySmallScreen
                            ? 16
                            : isSmallScreen
                            ? 17
                            : 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        isloading = true;
                      });
                      _submitProductionRequest();
                      setState(() {
                        isloading = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitProductionRequest() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final itemsToSubmit = filteredItems
          .where((item) => widget.role == "admin" ? item.isApproved : true)
          .where((item) => item.quantity > 0)
          .map(
            (item) => {
              "productId": item.productId,
              "qty": item.quantity, // إرسال الرقم كما هو بدون تقريب
              "package": item.package,
              "packageUnitname": item.packageUnitname,
            },
          )
          .toList();

      if (itemsToSubmit.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا توجد أصناف معتمدة للإرسال'.tr()),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final response = await http
          .post(
            Uri.parse(submitUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "isAdmin": widget.role == "admin",
              "items": itemsToSubmit,
              "isSend": false,
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${data["message"]}",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 3),
          ),
        );

        _loadProductionRequests();
        _loadAcceptedRequests();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'فشل الإنتاج'.tr());
      }
    } catch (e) {
      print("Error submitting production: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في العملية'.tr(),
            style: GoogleFonts.cairo(fontSize: 16),
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
  }) : package = (package == "لم يحدد") ? "" : package,
       packageUnitname = packageUnitname ?? "";
}

class AcceptedItem {
  String id;
  String productId;
  String name;
  String package;
  String packageUnitname;
  double quantity;
  String status;
  String date;

  AcceptedItem({
    required this.id,
    required this.productId,
    required this.name,
    required String package,
    String? packageUnitname,
    required this.quantity,
    required this.status,
    required this.date,
  }) : package = (package == "لم يحدد") ? "" : package,
       packageUnitname = packageUnitname ?? "";
}
