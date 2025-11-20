import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/assets.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:saladafactory/features/home/presentation/view/widget/bannnerHome.dart';
import 'package:saladafactory/features/orderSupply/data/services/active_30minOrderSupplyServices.dart';
import 'package:saladafactory/features/orderSupply/presentation/view/widget/LastOrderSupplyView.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart' as flutter;

import '../../../../../core/utils/apiEndpoints.dart';

Future<void> createOrderSupply({
  required String branchId,
  required String productId,
  required String package,
  required String packageUnitID,
  required double qty,
  required String ordername,
  required String mainProductId,
}) async {
  try {
    final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.orderSupply.add);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'branch': branchId,
        'product': productId,
        'packageUnit': packageUnitID,
        'package': package.isEmpty ? "لم يحدد" : package,
        'qty': qty,
        "ordername": ordername,
        "mainProductOP": mainProductId,
      }),
    ).timeout(const Duration(minutes: 10));

    if (response.statusCode != 200) {
      throw Exception('فشل في إرسال الطلب: ${response.statusCode} - ${response.body}');
    }
   await Active30minordersupplyservices.make();
  } catch (e) {
    throw Exception('حدث خطأ في الاتصال: $e');
  }
}

// دالة جديدة للتحقق من وجود طلبات غير مرسلة في الفرع
Future<bool> checkPendingOrders(String branchId) async {
  try {
    final url = Uri.parse(Apiendpoints.baseUrl + Apiendpoints.orderSupply.getOrderSof2Days);
    final response = await http.get(url).timeout(const Duration(minutes: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> orders = data['data'];
      
      // البحث عن أي طلب للفرع المحدد لم يتم إرساله بعد
      final hasPendingOrders = orders.any((order) => 
          order['branch']['_id'] == branchId && order['isSend'] == false);
      
      return hasPendingOrders;
    }
    return false;
  } catch (e) {
    throw Exception('حدث خطأ في التحقق من الطلبات: $e');
  }
}

class OrderSupplyBody extends StatefulWidget {
var canedit;
var usercanedite;
OrderSupplyBody({required this.canedit,required this.usercanedite});
  @override
  _OrderSupplyScreenState createState() => _OrderSupplyScreenState();
}

class _OrderSupplyScreenState extends State<OrderSupplyBody> {
  String? selectedBranchId;
  List<Branch> branches = [];
  List<Product> products = [];
  bool isLoadingBranches = true;
  bool isLoadingProducts = false;
  bool isSubmitting = false;
  bool isCheckingOrders = false; // متغير جديد للتحقق من الطلبات
  final ScrollController _scrollController = ScrollController();
  final Map<String, TextEditingController> _quantityControllers = {};
  int _currentIndex = 0;

  final Color primaryColor = const Color(0xFF74826A);
  final Color accentColor = const Color(0xFFEDBE2C);
  final Color secondaryColor = const Color(0xFFCDBCA2);
  final Color backgroundColor = const Color(0xFFF3F4EF);
  final Color warningColor = const Color(0xFFFF6B35); // لون التحذير

  // أحجام متجاوبة بناءً على حجم الشاشة
  double get responsiveScale => MediaQuery.of(context).size.shortestSide / 360;
  
  double responsiveSize(double size) => size * responsiveScale;
  
  double get iconSize => responsiveSize(16);
  double get smallIconSize => responsiveSize(14);
  double get fontSizeS => responsiveSize(10);
  double get fontSizeM => responsiveSize(12);
  double get fontSizeL => responsiveSize(14);
  double get fontSizeXL => responsiveSize(16);
  double get fontSizeXXL => responsiveSize(18);
  double get buttonHeight => responsiveSize(44);
  double get fieldHeight => responsiveSize(36);
  double get cardPadding => responsiveSize(10);
  double get elementSpacing => responsiveSize(8);

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  @override
  void dispose() {
    _quantityControllers.values.forEach((controller) => controller.dispose());
    _quantityControllers.clear();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchBranches() async {
    try {
      setState(() => isLoadingBranches = true);
      var token;
      await Localls.getToken().then((v)=>token=v);
      
      final userBranchesResponse = await http
          .get(Uri.parse(Apiendpoints.baseUrl + 'auth/user/BranchOS'),headers: {
            "Authorization":"Bearer $token"
          })
          .timeout(const Duration(minutes: 10));
      
      final allBranchesResponse = await http
          .get(Uri.parse(Apiendpoints.baseUrl + Apiendpoints.branch.getall))
          .timeout(const Duration(minutes: 10));
      
      if (userBranchesResponse.statusCode == 200 && allBranchesResponse.statusCode == 200) {
        final userBranchesData = json.decode(userBranchesResponse.body);
        final allBranchesData = json.decode(allBranchesResponse.body);
        
        final List<dynamic> userBranchesList = userBranchesData['data'];
        final List<dynamic> allBranchesList = allBranchesData['data'];
        
        final userBranchIds = userBranchesList.map((branch) => branch['_id'].toString()).toSet();
        
        setState(() {
          branches = allBranchesList.map((branch) {
            final isUserBranch = userBranchIds.contains(branch['_id'].toString());
            return Branch.fromJson(branch, isUserBranch: isUserBranch);
          }).toList();
          isLoadingBranches = false;
        });
      } else {
        throw Exception('Failed to load branches');
      }
    } on TimeoutException {
      setState(() => isLoadingBranches = false);
      _showErrorSnackbar('تم انتهاء المهلة، يرجى المحاولة مرة أخرى'.tr());
    } catch (e) {
      setState(() => isLoadingBranches = false);
      _showErrorSnackbar("حدث خطأ في جلب الفروع".tr());
    }
  }

  Future<void> _fetchProductsForBranch(String branchId) async {
    setState(() {
      selectedBranchId = branchId;
      isLoadingProducts = true;
      products = [];
    });

    try {
      final branch = branches.firstWhere((branch) => branch.id == branchId);
      
      if (!branch.isUserBranch) {
        _showErrorSnackbar('غير مسموح بالوصول لهذا الفرع'.tr());
        setState(() => isLoadingProducts = false);
        return;
      }
      
      _quantityControllers.values.forEach((c) => c.dispose());
      _quantityControllers.clear();
      
      setState(() {
        products = branch.products
            .where((p) => p.isorderSupply)
            .map((p) {
              final controller = TextEditingController();
              _quantityControllers[p.id] = controller;
              return Product(
                id: p.id,
                name: p.name,
                packSize: p.packSize,
                mainProductName: p.mainProductName,
                quantity: 0,
                mainProductid: p.mainProductid, 
                isorderSupply: p.isorderSupply, 
                packageUnitID: p.packageUnitID, 
                packageUnitname: p.packageUnitname,
              );
            })
            .toList();
        isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => isLoadingProducts = false);
      _showErrorSnackbar('حدث خطأ في جلب المنتجات'.tr());
    }
  }

Widget _buildQuantityField(Product product) {
  final controller = _quantityControllers[product.id]!;

  // تحديث الحقل عند البداية فقط
  if (controller.text.isEmpty && product.quantity > 0) {
    controller.text = product.quantity % 1 == 0
        ? product.quantity.toInt().toString()
        : product.quantity.toString();
  }

  return Container(
    height: fieldHeight,
    decoration: BoxDecoration(
      border: Border.all(color: primaryColor.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(responsiveSize(6)),
    ),
    child: Row(
      children: [
        // زرار الناقص
        Container(
          width: fieldHeight,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(responsiveSize(6)),
              bottomRight: Radius.circular(responsiveSize(6)),
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.remove, size: smallIconSize),
            padding: EdgeInsets.all(responsiveSize(2)),
            onPressed: () {
              final currentValue = product.quantity;
              final newValue = (currentValue - 1).clamp(0, double.infinity);
              setState(() {
product.quantity = newValue.toDouble();
                controller.text = newValue % 1 == 0
                    ? newValue.toInt().toString()
                    : newValue.toString();
              });
            },
          ),
        ),

        // حقل الإدخال
        Expanded(
          child: TextFormField(
            textAlign: TextAlign.center,
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              // يسمح بكتابة 0.5 أو أرقام عشرية
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: responsiveSize(4)),
              hintText: '',
              hintStyle: GoogleFonts.cairo(
                color: Colors.grey,
                fontSize: fontSizeM,
              ),
            ),
            style: GoogleFonts.cairo(fontSize: fontSizeM),
            onChanged: (value) {
              // نخزن القيمة فقط بدون تعديل النص
              if (value.isEmpty || value == ".") {
                setState(() {
                  product.quantity = 0;
                });
                return;
              }
              final parsedValue = double.tryParse(value);
              if (parsedValue != null) {
                setState(() {
                  product.quantity = parsedValue;
                });
              }
            },
            onEditingComplete: () {
              // ننسق الرقم فقط عند الانتهاء
              if (controller.text.isEmpty) {
                setState(() {
                  product.quantity = 0;
                  controller.text = "0";
                });
                return;
              }
              final parsedValue = double.tryParse(controller.text);
              if (parsedValue != null) {
                setState(() {
                  product.quantity = parsedValue;
                  controller.text = parsedValue % 1 == 0
                      ? parsedValue.toInt().toString()
                      : parsedValue.toString();
                });
              }
            },
          ),
        ),

        // زرار الزائد
        Container(
          width: fieldHeight,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(responsiveSize(6)),
              bottomLeft: Radius.circular(responsiveSize(6)),
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.add, size: smallIconSize),
            padding: EdgeInsets.all(responsiveSize(2)),
            onPressed: () {
              final currentValue = product.quantity;
              final newValue = currentValue + 1;
              setState(() {
                product.quantity = newValue;
                controller.text = newValue % 1 == 0
                    ? newValue.toInt().toString()
                    : newValue.toString();
              });
            },
          ),
        ),
      ],
    ),
  );
}




   List<ProductGroup> _groupProducts(List<Product> products) {
    final Map<String, ProductGroup> grouped = {};

    for (var product in products) {
      final mainProductName = product.mainProductName;
      if (grouped.containsKey(mainProductName)) {
        grouped[mainProductName]!.products.add(product);
      } else {
        grouped[mainProductName] = ProductGroup(
          name: mainProductName,
          products: [product],
        );
      }
    }

    return grouped.values.toList();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontSize: fontSizeM)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showWarningSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontSize: fontSizeM)),
        backgroundColor: warningColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  bool isloading = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ModalProgressHUD(
        color: Colors.black,
        opacity: 0.6,
        inAsyncCall: isloading,
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            centerTitle: true,
            title: Text('طلبات'.tr(),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: fontSizeXL,
                  fontWeight: FontWeight.bold,
                )),
            backgroundColor: primaryColor,
            elevation: 0,
          ),
          body: _buildCurrentScreen(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart, size: iconSize),
                label: 'طلب توريد'.tr(),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history, size: iconSize),
                label: 'آخر طلب'.tr(),
              ),
            ],
            selectedItemColor: accentColor,
            unselectedItemColor: Colors.grey,
            backgroundColor: primaryColor,
            selectedLabelStyle: GoogleFonts.cairo(fontSize: fontSizeS),
            unselectedLabelStyle: GoogleFonts.cairo(fontSize: fontSizeS),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildOrderSupplyScreen();
      case 1:
        return LastOrderSupplyview(role: "user", canedite: widget.canedit, usercanedite: widget.usercanedite,);
      default:
        return _buildOrderSupplyScreen();
    }
  }

  Widget _buildOrderSupplyScreen() {
    return isLoadingBranches
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              children: [
                if (branches.any((branch) => branch.isUserBranch))
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(responsiveSize(10))),
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedBranchId,
                        decoration: InputDecoration(
                          labelText: 'اختر الفرع'.tr(),
                          labelStyle: GoogleFonts.cairo(
                            color: primaryColor,
                            fontSize: fontSizeM,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(responsiveSize(6))),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: responsiveSize(12),
                            vertical: responsiveSize(8),
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items: branches.where((branch) => branch.isUserBranch).map((branch) {
                          return DropdownMenuItem<String>(
                            value: branch.id,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      branch.name, 
                                      style: GoogleFonts.cairo(
                                        color: primaryColor,
                                        fontSize: fontSizeM,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  SizedBox(width: elementSpacing),
                                  Image.asset(
                                    AssetIcons.track, 
                                    height: iconSize, 
                                    width: iconSize,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _fetchProductsForBranch(value);
                          }
                        },
                        style: GoogleFonts.cairo(fontSize: fontSizeM),
                      ),
                    ),
                  ),
                SizedBox(height: elementSpacing * 2),
                
                if (!branches.any((branch) => branch.isUserBranch))
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Text(
                          'لا توجد فروع متاحة للاختيار'.tr(),
                          style: GoogleFonts.cairo(
                            color: primaryColor, 
                            fontSize: fontSizeL,
                            
                          ),
                        ),
                      ),
                    ),
                  )
                else if (isLoadingProducts)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: responsiveSize(2),
                      )
                    ),
                  )
                else if (selectedBranchId != null && products.isNotEmpty) ...[
                  // رأس الجدول
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: responsiveSize(8), 
                      vertical: responsiveSize(10),
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(responsiveSize(6)),
                    ),
                    child: _buildTableHeader(),
                  ),
                  SizedBox(height: elementSpacing),
                  
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _groupProducts(products).length,
                      itemBuilder: (context, index) =>
                          _buildProductGroupItem(_groupProducts(products)[index]),
                    ),
                  ),
                  SizedBox(height: elementSpacing * 2),
                  
                  SafeArea(
                    top: false,
                    child: Center(
                      child: ElevatedButton.icon(
                        icon: isSubmitting || isCheckingOrders
                            ? SizedBox(
                                width: responsiveSize(18),
                                height: responsiveSize(18),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: responsiveSize(2),
                                ),
                              )
                            : Icon(
                                Icons.send, 
                                color: Colors.white, 
                                size: iconSize,
                              ),
                        label: Text('إرسال الطلبية'.tr(),
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: fontSizeL,
                              fontWeight: FontWeight.bold,
                            )),
                        onPressed: isSubmitting || isCheckingOrders ? null : _checkAndShowConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: EdgeInsets.symmetric(
                              horizontal: responsiveSize(20), 
                              vertical: responsiveSize(12)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(responsiveSize(10))),
                          minimumSize: Size(
                            responsiveSize(200), 
                            buttonHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else if (selectedBranchId != null)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Text(
                          'لا توجد منتجات متاحة في هذا الفرع'.tr(),
                          style: GoogleFonts.cairo(
                              color: primaryColor, 
                              fontSize: fontSizeL,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Text(
                          'الرجاء اختيار فرع لعرض المنتجات'.tr(),
                          style: GoogleFonts.cairo(
                              color: primaryColor, 
                              fontSize: fontSizeL,
                              
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
  }

  Widget _buildTableHeader() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          flex: 3,
          child: Text('القسم/الصنف'.tr(),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: fontSizeM,
              )),
        ),
        Expanded(
          flex: 2,
          child: Text('الحجم'.tr(),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: fontSizeM,
              ),
              textAlign: TextAlign.center),
        ),
        Expanded(
          flex: 3,
          child: Text('الكمية'.tr(),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: fontSizeM,
              ),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildProductGroupItem(ProductGroup group) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: elementSpacing),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsiveSize(6)),
      ),
      child: Container(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: GoogleFonts.cairo(
                  fontSize: fontSizeL,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: elementSpacing),
              ...group.products
                  .where((p) => p.isorderSupply)
                  .map((product) => _buildProductRow(product))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(Product product) {
    return Container(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: elementSpacing),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                product.name,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: const Color.fromARGB(255, 85, 69, 45),
                  fontSize: fontSizeM,
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                product.packSize.isEmpty ? "" : 
                product.packSize + " " + product.packageUnitname,
                style: GoogleFonts.cairo(
                  color: const Color.fromARGB(255, 128, 108, 79),
                  fontWeight: FontWeight.w500,
                  fontSize: fontSizeS,
                ),
                
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildQuantityField(product),
            ),
          ],
        ),
      ),
    );
  }

  // دالة جديدة للتحقق من الطلبات قبل إظهار dialog التأكيد
  Future<void> _checkAndShowConfirmationDialog() async {
    final orderedProducts = products.where((p) => p.quantity > 0).toList();

    if (orderedProducts.isEmpty) {
      _showErrorSnackbar('الرجاء تحديد كميات للمنتجات'.tr());
      return;
    }

    setState(() => isCheckingOrders = true);

    try {
      // التحقق من وجود طلبات غير مرسلة في الفرع المحدد
      final hasPendingOrders = await checkPendingOrders(selectedBranchId!);
      
      if (hasPendingOrders) {
        _showPendingOrdersWarning();
      } else {
        _showConfirmationDialog();
      }
    } catch (e) {
      _showErrorSnackbar('حدث خطأ في التحقق من الطلبات: $e');
    } finally {
      setState(() => isCheckingOrders = false);
    }
  }

  void _showPendingOrdersWarning() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection:flutter.TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveSize(14)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding * 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded, 
                    color: warningColor, 
                    size: responsiveSize(40),
                  ),
                  SizedBox(height: elementSpacing * 2),
                  Text(
                    'يوجد طلبات معلقة'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: fontSizeXL, 
                      fontWeight: FontWeight.bold,
                      color: warningColor,
                    ),
                  ),
                  SizedBox(height: elementSpacing * 2),
                  Text(
                    "لا يمكن ارسال طلب جديد هناك طلب قائم يمكن تعديلة".tr(),
                    style: GoogleFonts.cairo(fontSize: fontSizeM),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: elementSpacing * 3),
                  ElevatedButton(
                    child: Text(
                      'حسناً'.tr(),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: fontSizeM,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: warningColor,
                      padding: EdgeInsets.symmetric(
                          horizontal: responsiveSize(16), 
                          vertical: responsiveSize(10)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(responsiveSize(6))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    final orderedProducts = products.where((p) => p.quantity > 0).toList();

    if (orderedProducts.isEmpty) {
      _showErrorSnackbar('الرجاء تحديد كميات للمنتجات'.tr());
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection:flutter.TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveSize(14)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding * 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded, 
                    color: Colors.amber, 
                    size: responsiveSize(40),
                  ),
                  SizedBox(height: elementSpacing * 2),
                  Text(
                    'تأكيد الطلب'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: fontSizeXL, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(height: elementSpacing * 2),
                  Text(
                    'هل أنت متأكد من إرسال الطلبية؟'.tr(),
                    style: GoogleFonts.cairo(fontSize: fontSizeM),
                    
                  ),
                  SizedBox(height: elementSpacing * 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        child: Text(
                          'إلغاء'.tr(),
                          style: GoogleFonts.cairo(
                            color: primaryColor,
                            fontSize: fontSizeM,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        child: isSubmitting
                            ? SizedBox(
                                width: responsiveSize(18),
                                height: responsiveSize(18),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: responsiveSize(2),
                                ),
                              )
                            : Text(
                                'تأكيد'.tr(),
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: fontSizeM,
                                ),
                              ),
                        onPressed: isSubmitting ? null : () {
                          Navigator.pop(context);
                          _submitOrder();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: EdgeInsets.symmetric(
                              horizontal: responsiveSize(16), 
                              vertical: responsiveSize(10)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(responsiveSize(6))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    final orderedProducts = products.where((p) => p.quantity > 0).toList();

    setState(() => isSubmitting = true);

    try {
      setState(() {
        isloading = true;
      });
      var now = DateTime.now();
      var orderNameM = 'طلب توريد - ${now.day}/${now.month}/${now.year} - ${now.hour}:${now.minute}';

      for (var p in orderedProducts) {
        await createOrderSupply(
          branchId: selectedBranchId!,
          productId: p.id,
          package: p.packSize ?? "",
          qty: p.quantity,
          ordername: orderNameM,
          mainProductId: p.mainProductid, 
          packageUnitID: p.packageUnitID,
        );
      }
      setState(() {
        isloading = false;
      });
      _showSuccessDialog();

    } catch (e) {
      setState(() {
        isloading = false;
      });
      _showErrorSnackbar('${"حدث خطأ أثناء إرسال الطلب".tr()} : $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: flutter.TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveSize(14)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding * 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle, 
                    color: Colors.green, 
                    size: responsiveSize(50),
                  ),
                  SizedBox(height: elementSpacing * 2),
                  Text(
                    'تم بنجاح!'.tr(), 
                    style: GoogleFonts.cairo(
                      fontSize: fontSizeXL, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(height: elementSpacing),
                  Text(
                    'تم إرسال الطلب بنجاح'.tr(),
                    style: GoogleFonts.cairo(fontSize: fontSizeM),
                    
                  ),
                  SizedBox(height: elementSpacing * 2),
                  ElevatedButton(
                    child: Text(
                      'حسناً'.tr(), 
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: fontSizeM,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(responsiveSize(6)),
                      ),
                      minimumSize: Size(
                        responsiveSize(120), 
                        responsiveSize(36),
                      ),
                    ),
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

class Branch {
  final String id;
  final String name;
  final List<Product> products;
  final bool isUserBranch;

  Branch({
    required this.id,
    required this.name,
    required this.products,
    required this.isUserBranch,
  });

  factory Branch.fromJson(Map<String, dynamic> json, {bool isUserBranch = false}) {
    return Branch(
      id: json['_id'].toString(),
      name: json['name'].toString(),
      products: json['product'] != null
          ? (json['product'] as List).map((p) => Product.fromJson(p)).toList()
          : [],
      isUserBranch: isUserBranch,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String packSize;
  final String packageUnitID;
  final String packageUnitname;
  final String mainProductName;
  final String mainProductid;
  double quantity;
  bool isorderSupply;

  Product({
    required this.id,
    required this.name,
    required this.packSize,
    required this.packageUnitID,
    required this.packageUnitname,
    required this.mainProductName,
    required this.mainProductid,
    required this.isorderSupply,
    this.quantity = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'].toString(),
      name: json['name'].toString(),
      packSize: json['packSize']?.toString() ?? "",
      mainProductName: json['mainProductOP']?['name']?.toString() ??"",
      mainProductid: json['mainProductOP']?['_id']?.toString() ?? "",
      isorderSupply: json['isorderSupply'] ?? false,
      packageUnitID: json['packageUnit']?['_id']?.toString() ?? '',
      packageUnitname: json['packageUnit']?['name']?.toString() ?? '',
    );
  }
}

class ProductGroup {
  final String name;
  final List<Product> products;

  ProductGroup({required this.name, required this.products});
}