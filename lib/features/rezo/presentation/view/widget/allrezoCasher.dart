import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class Allrezocasher extends StatefulWidget {
  const Allrezocasher({super.key});

  @override
  State<Allrezocasher> createState() => _AllrezoCasherState();
}

class _AllrezoCasherState extends State<Allrezocasher> {
  // الألوان الجديدة
  final Color primaryColor = Color(0xFF74826A);
  final Color secondaryColor = Color(0xFFEDBE2C);
  final Color accentColor = Color(0xFFCDBCA2);
  final Color backgroundColor = Color(0xFFF3F4EF);

  List<dynamic> WasteData = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWasteData();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _fetchWasteData() async {
    try {
      final response = await http.get(
        Uri.parse(Apiendpoints.baseUrl + Apiendpoints.tawalf.getall),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          _safeSetState(() {
            WasteData = responseData['data'] ?? [];
            isLoading = false;
          });
        } else {
          _safeSetState(() {
            errorMessage =  'فشل في جلب البيانات'.tr();
            isLoading = false;
          });
        }
      } else {
        _safeSetState(() {
          errorMessage = 'خطأ في الاتصال'.tr();
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _safeSetState(() {
        errorMessage = 'حدث خطأ'.tr();
        isLoading = false;
      });
    }
  }

  DateTime _toSaudiTime(DateTime utcTime) {
    // السعودية في UTC+3
    return utcTime.add(Duration(hours: 3));
  }

  String _formatDateToSaudi(String dateString) {
    try {
      DateTime utcDate = DateTime.parse(dateString);
      DateTime saudiDate = _toSaudiTime(utcDate);
      return "${saudiDate.year}-${saudiDate.month.toString().padLeft(2, '0')}-${saudiDate.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return "تاريخ غير معروف".tr();
    }
  }

  String _formatTimeToSaudi(String dateString) {
    try {
      DateTime utcDate = DateTime.parse(dateString);
      DateTime saudiDate = _toSaudiTime(utcDate);
      return "${saudiDate.hour.toString().padLeft(2, '0')}:${saudiDate.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "وقت غير معروف".tr();
    }
  }

  // دالة للحصول على التاريخ والوقت الكامل بتوقيت السعودية
  String _formatFullDateTimeToSaudi(String dateString) {
    try {
      DateTime utcDate = DateTime.parse(dateString);
      DateTime saudiDate = _toSaudiTime(utcDate);
      return "${saudiDate.year}-${saudiDate.month.toString().padLeft(2, '0')}-${saudiDate.day.toString().padLeft(2, '0')} ${saudiDate.hour.toString().padLeft(2, '0')}:${saudiDate.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "تاريخ ووقت غير معروف".tr();
    }
  }

  Future<void> _updateWasteItem(String id, double newQty) async {
    try {
      final response = await http.put(
        Uri.parse('${Apiendpoints.baseUrl}${Apiendpoints.tawalf.update}$id'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'qty': newQty,
        }),
      ).timeout(Duration(minutes: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          _safeSetState(() {
            int index = WasteData.indexWhere((item) => item['_id'] == id);
            if (index != -1) {
              WasteData[index]['qty'] = newQty;
            }
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تعديل الكمية بنجاح'.tr()),
                backgroundColor: primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'فشل في التعديل'.tr()),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الاتصال'.tr()),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("حدث خطأ".tr()),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showEditDialog(Map<String, dynamic> item) {
    if (!mounted) return;
    
    TextEditingController qtyController = TextEditingController(
      text: item['qty'].toString()
    );
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: SingleChildScrollView( // إضافة SingleChildScrollView لمنع الـ overflow
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 30,
                    color: primaryColor,
                  ),
                ),
                
                SizedBox(height: 16),
                
                Text(
                  'تعديل الكمية'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                
                SizedBox(height: 16),
                
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_rounded, color: primaryColor, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['product']?['name'] ?? 'غير محدد'.tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                TextFormField(
                  controller: qtyController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'الكمية الجديدة'.tr(),
                    labelStyle: GoogleFonts.cairo(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    prefixIcon: Icon(Icons.scale_rounded, color: primaryColor, size: 20),
                    suffixText: item['unite']?['name'] ?? '',
                    suffixStyle: GoogleFonts.cairo(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                  ),
                ),

                // عرض التاريخ والوقت بتوقيت السعودية
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: secondaryColor, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'التاريخ والوقت (توقيت السعودية)',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatFullDateTimeToSaudi(item['createdAt']),
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: Text(
                          'إلغاء'.tr(),
                          style: GoogleFonts.cairo(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (qtyController.text.isNotEmpty) {
                            double newQty = double.tryParse(qtyController.text) ?? 0;
                            Navigator.of(context).pop();
                            _updateWasteItem(item['_id'], newQty);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          'حفظ'.tr(),
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // دالة معرض الصور مع الزوم والسحب
  void _showImageGallery(List<dynamic> allItems, int initialIndex) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                PhotoViewGallery.builder(
                  scrollPhysics: BouncingScrollPhysics(),
                  builder: (BuildContext context, int index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: NetworkImage(allItems[index]['image']),
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained * 0.8,
                      maxScale: PhotoViewComputedScale.covered * 2,
                      heroAttributes: PhotoViewHeroAttributes(tag: allItems[index]['_id']),
                    );
                  },
                  itemCount: allItems.length,
                  loadingBuilder: (context, event) => Center(
                    child: Container(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        value: event == null
                            ? 0
                            : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                      ),
                    ),
                  ),
                  backgroundDecoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                  ),
                  pageController: PageController(initialPage: initialIndex),
                  onPageChanged: (int index) {
                    // يمكنك إضافة أي تفاعل عند تغيير الصفحة هنا
                  },
                ),
                
                // زر الإغلاق
                Positioned(
                  top: 40,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
                
                // مؤشر الصور
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${initialIndex + 1} / ${allItems.length}',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        if (allItems[initialIndex]['product']?['name'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              allItems[initialIndex]['product']?['name'] ?? '',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
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

  // دالة عرض تفاصيل المنتج مع السحب يمين ويسار
  void _showProductDetailsWithSwipe(Map<String, dynamic> initialItem, List<dynamic> allItems) {
    if (!mounted) return;
    
    int initialIndex = allItems.indexWhere((element) => element['_id'] == initialItem['_id']);
    if (initialIndex == -1) initialIndex = 0;

    // متغير لتتبع السحب
    double startDragX = 0;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: ConstrainedBox( // استخدام ConstrainedBox بدلاً من Container
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85, // تقليل الارتفاع قليلاً
            ),
            child: SingleChildScrollView( // إضافة SingleChildScrollView
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with navigation buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (initialIndex > 0)
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios, color: primaryColor, size: 20),
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (mounted) {
                                _showProductDetailsWithSwipe(allItems[initialIndex - 1], allItems);
                              }
                            },
                          )
                        else
                          SizedBox(width: 40),

                        Column(
                          children: [
                            Text(
                              'تفاصيل المنتج'.tr(),
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${initialIndex + 1} / ${allItems.length}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        if (initialIndex < allItems.length - 1)
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios, color: primaryColor, size: 20),
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (mounted) {
                                _showProductDetailsWithSwipe(allItems[initialIndex + 1], allItems);
                              }
                            },
                          )
                        else
                          SizedBox(width: 40),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // المحتوى الرئيسي مع إمكانية السحب
                    GestureDetector(
                      onHorizontalDragStart: (details) {
                        startDragX = details.globalPosition.dx;
                      },
                      onHorizontalDragEnd: (details) {
                        final double endDragX = details.primaryVelocity ?? 0;
                        final double dragDistance = startDragX - details.globalPosition.dx;
                        
                        // إذا كانت مسافة السحب كبيرة enough (أكثر من 50 بكسل)
                        if (dragDistance.abs() > 50) {
                          if (dragDistance > 0 && initialIndex < allItems.length - 1) {
                            // سحب لليسار - التالي
                            Navigator.of(context).pop();
                            if (mounted) {
                              _showProductDetailsWithSwipe(allItems[initialIndex + 1], allItems);
                            }
                          } else if (dragDistance < 0 && initialIndex > 0) {
                            // سحب لليمين - السابق
                            Navigator.of(context).pop();
                            if (mounted) {
                              _showProductDetailsWithSwipe(allItems[initialIndex - 1], allItems);
                            }
                          }
                        }
                        
                        // أو استخدام السرعة للكشف عن السحب السريع
                        if (endDragX < -100 && initialIndex < allItems.length - 1) {
                          // سحب سريع لليسار - التالي
                          Navigator.of(context).pop();
                          if (mounted) {
                            _showProductDetailsWithSwipe(allItems[initialIndex + 1], allItems);
                          }
                        } else if (endDragX > 100 && initialIndex > 0) {
                          // سحب سريع لليمين - السابق
                          Navigator.of(context).pop();
                          if (mounted) {
                            _showProductDetailsWithSwipe(allItems[initialIndex - 1], allItems);
                          }
                        }
                      },
                      child: _buildProductDetailContent(allItems[initialIndex], allItems, initialIndex),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // الأزرار
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (mounted) {
                                _showEditDialog(allItems[initialIndex]);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              side: BorderSide(color: secondaryColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_outlined, size: 16, color: secondaryColor),
                                SizedBox(width: 4),
                                Text(
                                  'تعديل'.tr(),
                                  style: GoogleFonts.cairo(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(width: 8),
                        
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: Text(
                              'إغلاق'.tr(),
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
        );
      },
    );
  }

  Widget _buildProductDetailContent(
      Map<String, dynamic> item, List<dynamic> allItems, int currentIndex) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // صورة المنتج مع إمكانية الزوم والسحب
        GestureDetector(
          onTap: () {
            _showImageGallery(allItems, currentIndex);
          },
          child: Stack(
            children: [
              // خلفية الصورة
              Container(
                height: 300, // تقليل الارتفاع لتوفير مساحة
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: backgroundColor,
                  image: item['image'] != null && item['image'].isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(item['image']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item['image'] == null || item['image'].isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'لا توجد صورة',
                            style: GoogleFonts.cairo(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),

              // طبقة شفافة فوق الصورة
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),

              // بيانات المنتج فوق الصورة
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item['product']?['name'] ?? 'غير محدد'.tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: primaryColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            '${item['qty']} ${item['unite']?['name']}' ?? 'غير محدد'.tr(),
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // معلومات التاريخ والوقت بتوقيت السعودية
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateToSaudi(item['createdAt']),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _formatTimeToSaudi(item['createdAt']) + ' (توقيت السعودية)',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // زر الزوم في الزاوية
              if (item['image'] != null && item['image'].isNotEmpty)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.zoom_in_map, size: 16, color: primaryColor),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _showImageGallery(allItems, currentIndex);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),

        SizedBox(height: 10),
        
        // معلومات المنتج
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildDetailChip(Icons.person, item['userId']?['name'] ?? 'غير محدد'.tr(), primaryColor),
            _buildDetailChip(Icons.store, item['branch']?['name'] ?? 'غير محدد'.tr(), secondaryColor),
            _buildDetailChip(Icons.calendar_today, _formatDateToSaudi(item['createdAt']), accentColor),
            _buildDetailChip(Icons.access_time, _formatTimeToSaudi(item['createdAt']), Colors.blue),
          ],
        ),

     
      ],
    );
  }

  // ويدجت جديدة لعرض المعلومات بشكل chips
  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSlider(List<dynamic> products, String date) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  primaryColor,
                  accentColor,
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.calendar_today, color: Colors.white, size: 16),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التاريخ:'.tr() +' '+ '$date',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${products.length}' +'عنصر'.tr() + ' (توقيت السعودية)',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    products.length.toString(),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            height: 222,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final item = products[index];
                return Container(
                  width: 150,
                  margin: EdgeInsets.symmetric(horizontal: 6.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () {
                        List<dynamic> allProducts = [];
                        for (var entry in _getGroupedData().entries) {
                          allProducts.addAll(entry.value);
                        }
                        if (mounted) {
                          _showProductDetailsWithSwipe(item, allProducts);
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  image: item['image'] != null && item['image'].isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(item['image']),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: item['image'] != null && item['image'].isNotEmpty
                                      ? Colors.transparent
                                      : backgroundColor,
                                ),
                                child: item['image'] == null || item['image'].isEmpty
                                    ? Icon(
                                        Icons.inventory_2_rounded,
                                        color: accentColor,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                            
                            SizedBox(height: 8),
                            
                            Text(
                              item['product']?['name'] ?? 'غير محدد'.tr(),
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                height: 1.3,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            SizedBox(height: 6),
                            
                            _buildProductInfo(
                              Icons.scale_rounded,
                              '${item['qty']} ${item['unite']?['name'] ?? ''}',
                              primaryColor,
                            ),
                            
                            SizedBox(height: 4),
                            
                            _buildProductInfo(
                              Icons.store_rounded,
                              item['branch']?['name'] ?? 'غير محدد'.tr(),
                              secondaryColor,
                            ),

                            SizedBox(height: 4),
                            
                            _buildProductInfo(
                              Icons.access_time,
                              _formatTimeToSaudi(item['createdAt']),
                              Colors.blue,
                            ),
                            
                            Spacer(),
                            
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'التفاصيل'.tr(),
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_back, size: 10, color: primaryColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    
    _safeSetState(() {
      isLoading = true;
      errorMessage = '';
    });
    await _fetchWasteData();
  }

  Map<String, List<dynamic>> _getGroupedData() {
    Map<String, List<dynamic>> groupedData = {};
    
    for (var item in WasteData) {
      String date = _formatDateToSaudi(item['createdAt']);
      if (!groupedData.containsKey(date)) {
        groupedData[date] = [];
      }
      groupedData[date]!.add(item);
    }

    return groupedData;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<dynamic>> groupedData = _getGroupedData();

    List<MapEntry<String, List<dynamic>>> sortedEntries = groupedData.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'التوالف مفصل'.tr(),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 22),
            onPressed: _refreshData,
            tooltip: 'تحديث البيانات'.tr(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: isLoading
            ? _buildLoadingState()
            : errorMessage.isNotEmpty
                ? _buildErrorState()
                : sortedEntries.isEmpty
                    ? _buildEmptyState()
                    : _buildDataState(sortedEntries),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'جاري تحميل البيانات...'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'حدث خطأ'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                errorMessage,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'إعادة المحاولة'.tr(),
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 50,
                color: accentColor,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'لا توجد بيانات'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'لم يتم العثور على أي سجلات توالف'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'تحديث'.tr(),
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataState(List<MapEntry<String, List<dynamic>>> sortedEntries) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: primaryColor,
      backgroundColor: Colors.white,
      displacement: 20,
      strokeWidth: 2,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 12),
        itemCount: sortedEntries.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          String date = sortedEntries[index].key;
          List<dynamic> items = sortedEntries[index].value;
          
          return _buildProductSlider(items, date);
        },
      ),
    );
  }
}