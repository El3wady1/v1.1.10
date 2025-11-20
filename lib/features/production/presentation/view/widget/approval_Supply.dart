import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:saladafactory/core/utils/apiEndpoints.dart';

class Approvel_Supply extends StatefulWidget {
  final String role;
  Approvel_Supply({required this.role});
  
  @override
  _Approvel_SupplyState createState() => _Approvel_SupplyState();
}

class _Approvel_SupplyState extends State<Approvel_Supply> {
  List<AcceptedItem> acceptedItems = [];
  bool isLoading = false;
  String acceptedUrl = "${Apiendpoints.baseUrl}${Apiendpoints.productionSupply.getPending}";
  String updateQtyUrl = "${Apiendpoints.baseUrl}${Apiendpoints.productionSupply.updateQty}";
  String approveUrl = "${Apiendpoints.baseUrl}${Apiendpoints.productionSupply.approve}";
  String refuseUrl = "${Apiendpoints.baseUrl}${Apiendpoints.productionSupply.refusePendingRequest}";

  // ألوان متناسقة
  final Color primaryColor = Color(0xFF2E5E3A);
  final Color accentColor = Color(0xFFE6B905);
  final Color secondaryColor = Color(0xFF8B9E7E);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textColor = Color(0xFF333333);
  final Color lightTextColor = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _loadApprovel_Supply();
  }

  Future<void> _loadApprovel_Supply() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);
    
    try {
      final response = await http.get(Uri.parse(acceptedUrl)).timeout(Duration(seconds: 30));

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
            
            loadedItems.add(AcceptedItem(
              id: item['_id'] ?? '',
              productId: productData['_id'] ?? '',
              name: productData['name'] ?? 'غير معروف',
              package: productData['packSize']?.toString() ?? '0',
              quantity: (item['qty'] as num?)?.toDouble() ?? 0.0,
              status: item['status'] ?? 'pending',
              date: item['createdAt'] ?? '',
              packageUnitname: productData['packageUnit']?['name'] ?? "لم يحدد".tr(),
            ));
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
      final response = await http.put(
        Uri.parse('$updateQtyUrl$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'qty': newQuantity}),
      ).timeout(Duration(seconds: 30));

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
        _loadApprovel_Supply();
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
      final response = await http.post(
        Uri.parse(approveUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"requestIds": requestIds}),
      ).timeout(Duration(seconds: 30));

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
        _loadApprovel_Supply();
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
        final response = await http.delete(
          Uri.parse('$refuseUrl$id'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: 30));

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
      _loadApprovel_Supply();
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

  String _formatNumber(double number) {
    if (number % 1 == 0) {
      return number.toInt().toString();
    } else {
      return number.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
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
          vertical: isVerySmallScreen ? 10 : isSmallScreen ? 12 : 14,
          horizontal: isVerySmallScreen ? 8 : isSmallScreen ? 12 : 16,
        ),
        child: Row(
          children: [
            // اسم المنتج
            Expanded(
              flex: isLargeScreen ? 4 : 3,
              child: Text(
                item.name,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen ? 14 : isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            
            // الوزن
            Container(
              width: isLargeScreen ? 80 : (isVerySmallScreen ? 50 : isSmallScreen ? 60 : 70),
              alignment: Alignment.center,
              child: Text(
                "${item.package} ${item.packageUnitname}",
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 14 : 15,
                  color: lightTextColor,
                ),
              ),
            ),
            
            // الكمية مع إمكانية التعديل
            Container(
              width: isLargeScreen ? 70 : (isVerySmallScreen ? 50 : isSmallScreen ? 60 : 70),
              alignment: Alignment.center,
              child: InkWell(
                onTap: () => _showQuantityDialog(item),
                child: Text(
                  _formatNumber(item.quantity),
                  style: GoogleFonts.cairo(
                    fontSize: isVerySmallScreen ? 14 : isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    decoration: widget.role == "admin" ? TextDecoration.underline : TextDecoration.none,
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
                      fontSize: isVerySmallScreen ? 12 : isSmallScreen ? 13 : 14,
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
    
    TextEditingController qtyController = TextEditingController(text: _formatNumber(item.quantity));
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(isVerySmallScreen ? 14 : isSmallScreen ? 18 : 22),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Text('تعديل الكمية'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: isVerySmallScreen ? 18 : isSmallScreen ? 20 : 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    )),
              ),
              SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 20),
              Text('${item.name} - ${item.package} ${item.packageUnitname}',
                  style: GoogleFonts.cairo(
                    fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 17 : 18,
                    color: textColor,
                  )),
              SizedBox(height: isVerySmallScreen ? 8 : isSmallScreen ? 12 : 16),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
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
              SizedBox(height: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor, 
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallScreen ? 14 : isSmallScreen ? 18 : 22, 
                        vertical: isVerySmallScreen ? 10 : isSmallScreen ? 12 : 14,
                      ),
                    ),
                    child: Text('إلغاء'.tr(), 
                        style: GoogleFonts.cairo(
                          fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 17 : 18,
                          fontWeight: FontWeight.w600,
                        )),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: isVerySmallScreen ? 10 : isSmallScreen ? 14 : 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallScreen ? 18 : isSmallScreen ? 22 : 26, 
                        vertical: isVerySmallScreen ? 10 : isSmallScreen ? 12 : 14,
                      ),
                    ),
                    child: Text('حفظ'.tr(), 
                        style: GoogleFonts.cairo(
                          fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 17 : 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
                    onPressed: () {
                      final newQty = double.tryParse(qtyController.text) ?? item.quantity;
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
        title: Text('رفض الطلب'.tr(), 
            style: GoogleFonts.cairo(
              fontSize: isVerySmallScreen ? 18 : isSmallScreen ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            )),
        content: Text('هل أنت متأكد من رفض هذا الطلب؟'.tr(),
            style: GoogleFonts.cairo(
              fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 17 : 18,
              color: textColor,
            )),
        actions: [
          TextButton(
            child: Text('إلغاء'.tr(), 
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 17 : 18,
                  color: primaryColor,
                )),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('رفض'.tr(), 
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 17 : 18,
                  color: Colors.white,
                )),
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
    
    final pendingItems = acceptedItems.where((item) => item.status == "pending").toList();
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
        title: Text(isApprove ? 'اعتماد الكل'.tr() : 'رفض الكل'.tr(), 
            style: GoogleFonts.cairo(
              fontSize: isVerySmallScreen ? 18 : isSmallScreen ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            )),
        content: Text(isApprove 
            ? 'هل أنت متأكد من اعتماد جميع الطلبات القيد الانتظار؟'.tr()
            : 'هل أنت متأكد من رفض جميع الطلبات القيد الانتظار؟'.tr(),
            style: GoogleFonts.cairo(
              fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 17 : 18,
              color: textColor,
            )),
        actions: [
          TextButton(
            child: Text('إلغاء'.tr(), 
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 17 : 18,
                  color: primaryColor,
                )),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(isApprove ? 'اعتماد الكل'.tr() : 'رفض الكل'.tr(), 
                style: GoogleFonts.cairo(
                  fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 17 : 18,
                  color: Colors.white,
                )),
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
        horizontal: isVerySmallScreen ? 8.0 : isSmallScreen ? 12.0 : 16.0,
        vertical: isVerySmallScreen ? 4.0 : 8.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.check_circle, size: isVerySmallScreen ? 18 : 20),
              label: Text('اعتماد الكل'.tr(), 
                  style: GoogleFonts.cairo(
                    fontSize: isVerySmallScreen ? 14 : isSmallScreen ? 16 : 18,
                  )),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(
                  vertical: isVerySmallScreen ? 12 : isSmallScreen ? 14 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _showBulkActionDialog(true),
            ),
          ),
          SizedBox(width: isVerySmallScreen ? 8 : isSmallScreen ? 12 : 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.cancel, size: isVerySmallScreen ? 18 : 20),
              label: Text('رفض الكل'.tr(), 
                  style: GoogleFonts.cairo(
                    fontSize: isVerySmallScreen ? 14 : isSmallScreen ? 16 : 18,
                  )),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(
                  vertical: isVerySmallScreen ? 12 : isSmallScreen ? 14 : 16,
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

  Widget _buildAcceptedPage() {
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
                    Icon(Icons.list_alt,
                        size: isVerySmallScreen ? 55 : isSmallScreen ? 65 : 75, 
                        color: secondaryColor),
                    SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 20),
                    Text('لا توجد طلبات معتمدة'.tr(),
                        style: GoogleFonts.cairo(
                          fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20, 
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            )
          else ...[
            // قائمة العناصر
            Expanded(
              child: ListView.builder(
                itemCount: acceptedItems.length,
                itemBuilder: (context, index) {
                  return _buildAcceptedItemRow(acceptedItems[index], index);
                },
              ),
            ),
            
            // زر اعتماد الكل (للمشرف فقط)
            if (widget.role == "admin" && acceptedItems.any((item) => item.status == "pending"))
              Padding(
                padding: EdgeInsets.all(isVerySmallScreen ? 10.0 : isSmallScreen ? 14.0 : 18.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, 
                      backgroundColor: primaryColor,
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
                        Text('اعتماد الكل'.tr(),
                            style: GoogleFonts.cairo(
                              fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20, 
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                    onPressed: () {
                      final pendingIds = acceptedItems
                          .where((item) => item.status == "pending")
                          .map((item) => item.id)
                          .toList();
                      if (pendingIds.isNotEmpty) {
                        _approveRequests(pendingIds);
                      }
                    },
                  ),
                ),
              ),
          ],
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
        title: Text('ع. توريد'.tr(),style: GoogleFonts.cairo(fontSize: 16),),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildAcceptedPage(),
    );
  }
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
    required this.package,
    String? packageUnitname,
    required this.quantity,
    required this.status,
    required this.date,
  }) : packageUnitname = packageUnitname ?? "لم يحدد".tr();
}