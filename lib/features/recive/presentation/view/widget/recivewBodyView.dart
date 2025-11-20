import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:saladafactory/core/utils/assets.dart';
import 'package:saladafactory/features/product/presentation/view/productView.dart';
import 'package:saladafactory/features/recive/presentation/view/reciveView.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class OperationalDetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل العملية'),
        centerTitle: true,
        elevation: 10,
        shadowColor: Colors.blue.withOpacity(0.5),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'إرشادات استخدام شاشة استلام الأصناف',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25),
              _buildStep(
                stepNumber: 1,
                title: 'اختيار الفرع',
                description:
                    'يجب اختيار الفرع الذي سيتم استلام الأصناف فيه من القائمة المنسدلة.',
                icon: Icons.store,
              ),
              _buildStep(
                stepNumber: 2,
                title: 'مسح الباركود',
                description:
                    'اضغط على زر "مسح الباركود" لفتح الماسح الضوئي ومسح الأصناف.',
                icon: Icons.qr_code_scanner,
              ),
              _buildStep(
                stepNumber: 3,
                title: 'توجيه الكود',
                description:
                    'وجّه الكاميرا نحو باركود الصنف بحيث يكون داخل الإطار الظاهر على الشاشة.',
                icon: Icons.camera_alt,
              ),
              _buildStep(
                stepNumber: 4,
                title: 'إدخال الكمية',
                description:
                    'بعد كل عملية مسح ناجحة، ستظهر نافذة لإدخال كمية الصنف.',
                icon: Icons.format_list_numbered,
              ),
              _buildStep(
                stepNumber: 5,
                title: 'إدارة الأصناف',
                description:
                    'يمكن حذف أي صنف من القائمة عن طريق الضغط على أيقونة الحذف بجانبه.',
                icon: Icons.delete_outline,
              ),
              _buildStep(
                stepNumber: 6,
                title: 'تأكيد الاستلام',
                description:
                    'بعد إضافة جميع الأصناف، اضغط على زر "تأكيد الاستلام" لإتمام العملية.',
                icon: Icons.check_circle_outline,
              ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'ملاحظات مهمة:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildNote('يجب اختيار الفرع قبل البدء في مسح الأصناف.'),
                    _buildNote('سيتم إصدار صوت واهتزاز عند كل مسح ناجح.'),
                    _buildNote('لا يمكن إضافة نفس الصنف مرتين.'),
                    _buildNote('يجب أن تكون الكمية أكبر من الصفر.'),
                  ],
                ),
              ),
              SizedBox(height: 25),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 12),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Reciveview()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: Colors.blue.withOpacity(0.3),
                    ),
                    child: Text(
                      'بدء عملية الاستلام',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
      {required int stepNumber,
      required String title,
      required String description,
      required IconData icon}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: Colors.blue.shade600),
                      SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Recivewbodyview extends StatefulWidget {
  @override
  _RecivewbodyviewState createState() => _RecivewbodyviewState();
}

class _RecivewbodyviewState extends State<Recivewbodyview> {
  String? selectedBranch;
  List<Map<String, dynamic>> receivedItems = [];
  bool showScanner = false;
  final TextEditingController _quantityDialogController =
      TextEditingController();
  bool _isDialogOpen = false;
  bool _isLoading = false;

  final List<String> branches = ['فرع الرياض', 'فرع جدة', 'فرع الدمام'];
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void dispose() {
    audioPlayer.dispose();
    _quantityDialogController.dispose();
    super.dispose();
  }

  Future<void> scanBarcode(String barcode) async {
    if (_isDialogOpen) return;

    if (selectedBranch == null) {
      _showErrorSnackbar('الرجاء اختيار الفرع أولاً');
      return;
    }

    if (receivedItems.any((item) => item['barcode'] == barcode)) {
      _showErrorSnackbar('هذا الصنف مضاف مسبقاً');
      return;
    }

    await _playSuccessFeedback();
    String itemName = 'صنف ${barcode.substring(0, 4)}';
    _quantityDialogController.text = '1'; // تعيين قيمة افتراضية للكمية

    setState(() => _isDialogOpen = true);

    try {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24), // زيادة نصف القطر للحواف
  ),
  elevation: 16, // زيادة الارتفاع للظل
  shadowColor: Colors.blue.withOpacity(0.3), // لون ظل مخصص
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.shade50,
          Colors.white,
        ],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // العنوان مع تأثير مميز
              Container(
                margin: EdgeInsets.symmetric(vertical: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade100,
                      Colors.blue.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    'اسم الصنف : دواء',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      
              // حقل الباركود مع تصميم مميز
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code, color: Colors.blue.shade700),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'الباركود: $barcode',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
      
              // عداد الكمية مع تأثيرات مميزة
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'الكمية',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // زر النقصان مع تأثير
                        IconButton(
                          icon: Icon(Icons.remove_circle, size: 36),
                          color: Colors.red.shade400,
                          onPressed: () {
                            int currentValue = int.tryParse(
                                    _quantityDialogController.text) ??
                                1;
                            if (currentValue > 1) {
                              setState(() {
                                _quantityDialogController.text =
                                    (currentValue - 1).toString();
                              });
                            }
                          },
                        ),
      
                        // حقل الكمية مع تصميم مميز
                        Container(
                          width: 80,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: TextField(
                              controller: _quantityDialogController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ),
      
                        // زر الزيادة مع تأثير
                        IconButton(
                          icon: Icon(Icons.add_circle, size: 36),
                          color: Colors.green.shade400,
                          onPressed: () {
                            int currentValue = int.tryParse(
                                    _quantityDialogController.text) ??
                                1;
                            setState(() {
                              _quantityDialogController.text =
                                  (currentValue + 1).toString();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      
              if ((int.tryParse(_quantityDialogController.text) ?? 0) <= 0)
                Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    'يجب أن تكون الكمية أكبر من الصفر',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              SizedBox(height: 28),
      
              // أزرار التأكيد والإلغاء مع تأثيرات
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // زر الإلغاء مع تأثير
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  
                  // زر التأكيد مع تأثير جرادينت
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade600,
                          Colors.blue.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        final quantity = int.tryParse(
                                _quantityDialogController.text) ??
                            0;
                        if (quantity > 0) {
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'تأكيد',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
);  },
          );
        },
      );

      if (confirmed == true) {
        setState(() {
          receivedItems.add({
            'barcode': barcode,
            'name': itemName,
            'quantity': int.parse(_quantityDialogController.text),
          });
          showScanner = false;
        });
      }
    } finally {
      setState(() => _isDialogOpen = false);
    }
  }

  Future<void> _playSuccessFeedback() async {
    // await audioPlayer.play(AssetSource(AssetAudio.scanned));
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void confirmReceiving() {
    if (receivedItems.isEmpty) {
      _showErrorSnackbar('لم يتم إضافة أي أصناف');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              SizedBox(height: 10),
              Text(
                'تأكيد الاستلام',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "هل انت متأكد ؟",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              // Container(
              //   height: 150,
              //   child: SingleChildScrollView(
              //     child: Column(
              //       mainAxisSize: MainAxisSize.min,
              //       children: receivedItems
              //           .map(
              //             (item) => Padding(
              //               padding: EdgeInsets.symmetric(vertical: 6),
              //               child: Row(
              //                 children: [
              //                   Icon(Icons.saladafactory_2,
              //                       color: Colors.blue.shade600, size: 20),
              //                   SizedBox(width: 8),
              //                   Expanded(
              //                     child: Text(
              //                       '${item['name']}',
              //                       style: TextStyle(fontSize: 16),
              //                     ),
              //                   ),
              //                   Text(
              //                     '${item['quantity']}',
              //                     style: TextStyle(
              //                       fontSize: 16,
              //                       fontWeight: FontWeight.bold,
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           )
              //           .toList(),
              //     ),
              //   ),
              // ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text('إلغاء'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _finalizeReceiving();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: Text('تأكيد'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finalizeReceiving() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم تأكيد الاستلام بنجاح"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
      ),
    );

    setState(() {
      receivedItems.clear();
      selectedBranch = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('استلام الأصناف'),
          centerTitle: true,
          elevation: 5,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('جاري تأكيد عملية الاستلام...'),
                  ],
                ),
              )
            : showScanner
                ? _buildScanner()
                : _buildReceiveForm(),
      ),
    );
  }

  Widget _buildReceiveForm() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختيار الفرع',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBranch,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: branches.map((branch) {
                        return DropdownMenuItem(
                          value: branch,
                          child: Text(
                            branch,
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBranch = value;
                        });
                      },
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                      icon: Icon(Icons.arrow_drop_down),
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الأصناف المضافة',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    receivedItems.isEmpty
                        ? Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'لم يتم إضافة أي أصناف بعد',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: receivedItems.length,
                              itemBuilder: (context, index) {
                                var item = receivedItems[index];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.05),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade50,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                            color: Colors.blue.shade800),
                                      ),
                                    ),
                                    title: Text(
                                      item['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'الكمية: ${item['quantity']}',
                                      style: TextStyle(
                                          color: Colors.grey.shade600),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.red.shade400),
                                      onPressed: () {
                                        setState(() {
                                          receivedItems.removeAt(index);
                                        });
                                      },
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (selectedBranch == null) {
                  _showErrorSnackbar('الرجاء اختيار الفرع أولاً');
                  return;
                }
                setState(() => showScanner = true);
              },
              icon: Icon(Icons.qr_code_scanner, size: 24),
              label: Text(
                'مسح الباركود',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 56),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
            ),
            SizedBox(height: 12),
            if (receivedItems.isNotEmpty)
              ElevatedButton(
                onPressed: confirmReceiving,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 56),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Colors.green.withOpacity(0.3),
                ),
                child: Text(
                  'تأكيد الاستلام',
                  style: TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
            facing: CameraFacing.back,
          ),
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final barcode = barcodes.first.rawValue;
              if (barcode != null && !_isDialogOpen) {
                scanBarcode(barcode);
              }
            }
          },
        ),
        Positioned(
          top: 40,
          left: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () {
                setState(() => showScanner = false);
              },
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'وجّه الكود داخل الإطار للمسح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'الأصناف المضافة: ${receivedItems.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'فرع: ${selectedBranch ?? 'لم يتم الاختيار'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.green.withOpacity(0.8),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
