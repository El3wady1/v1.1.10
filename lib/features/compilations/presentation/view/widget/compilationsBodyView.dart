import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

import '../../../../../core/utils/apiEndpoints.dart';

class Compilationsbodyview extends StatefulWidget {
  @override
  _DamagesScreenState createState() => _DamagesScreenState();
}

class _DamagesScreenState extends State<Compilationsbodyview> {
  String? selectedBranch;
  List<Map<String, dynamic>> branches = [];
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> units = [];
  List<Map<String, dynamic>> selectedProducts = [];
  bool isLoading = false;
  bool isLoadingProducts = false;
  bool isLoadingUnits = false;
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? selectedProduct;
  TextEditingController quantityController = TextEditingController();
  File? currentProductImage;
  String? manuallySelectedUnitId;
  
  final Color primaryColor = Color(0xFF74826A);
  final Color secondaryColor = Color(0xFFEDBE2C);
  final Color accentColor = Color(0xFFCDBCA2);
  final Color backgroundColor = Color(0xFFF3F4EF);

  // متغيرات للتحكم في حالة الواجهة
  bool _isContentVisible = true;

  @override
  void initState() {
    super.initState();
    selectedProducts = [];
    _loadUserBranches(); // تغيير اسم الدالة
    _loadUnits();
  }

  // 🔥 دالة لإعادة بناء الواجهة بشكل آمن
  void _safeRebuild() {
    if (mounted) {
      setState(() {
        _isContentVisible = true;
      });
    }
  }

  // 🔥 دالة جديدة لجلب فروع المستخدم فقط
  Future<void> _loadUserBranches() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      var token;
      await Localls.getToken().then((v) => token = v);

      final response = await http.get(
        Uri.parse('${Apiendpoints.baseUrl}${Apiendpoints.auth.userBranchTawalf}'),
        headers: {
          'authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(minutes: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)["data"];

        if (data is List) {
          if (mounted) {
            setState(() {
              branches = List<Map<String, dynamic>>.from(data);
              isLoading = false;
              _isContentVisible = true;
            });
          }
        } else {
          print('هيكل البيانات غير متوقع: $data');
          throw Exception('هيكل البيانات غير متوقع'.tr());
        }
      } else {
        throw Exception('فشل في تحميل فروع المستخدم: ${response.statusCode}'.tr());
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isContentVisible = true;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحميل فروع المستخدم: ${error.toString()}'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  Future<void> _loadUnits() async {
    if (mounted) {
      setState(() {
        isLoadingUnits = true;
      });
    }

    try {
      final response = await http
          .get(Uri.parse('${Apiendpoints.baseUrl}${Apiendpoints.unit.getall}')).timeout(Duration(minutes: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body)["data"];

        if (data is List) {
          if (mounted) {
            setState(() {
              units = List<Map<String, dynamic>>.from(data);
              isLoadingUnits = false;
            });
          }
        } else {
          throw Exception('هيكل بيانات الوحدات غير متوقع: $data'.tr());
        }
      } else {
        throw Exception('فشل في تحميل الوحدات: ${response.statusCode}'.tr());
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoadingUnits = false;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحميل الوحدات: ${error.toString()}'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  Map<String, dynamic>? _findProductUnit(String productId) {
    try {
      for (var unit in units) {
        if (unit.containsKey('Tawalf_productOP') && unit['Tawalf_productOP'] is List) {
          final productsInUnit = List<Map<String, dynamic>>.from(unit['Tawalf_productOP']);
          final productExists = productsInUnit.any((product) => product['_id'] == productId);
          if (productExists) {
            return {
              'id': unit['_id'],
              'name': unit['name'] ?? 'غير محدد'.tr()
            };
          }
        }
      }
      
      try {
        final product = allProducts.firstWhere((p) => p['_id'] == productId);
        
        if (product['packageUnit'] != null && product['packageUnit'].toString().isNotEmpty) {
          final packageUnit = units.firstWhere(
            (unit) => unit['_id'] == product['packageUnit'],
            orElse: () => {},
          );
          
          if (packageUnit.isNotEmpty) {
            return {
              'id': packageUnit['_id'],
              'name': packageUnit['name'] ?? 'وحدة التغليف'.tr()
            };
          }
        }
      } catch (e) {
        print('خطأ في البحث عن وحدة المنتج: $e'.tr());
      }
      
      if (units.isNotEmpty) {
        return {
          'id': units.first['_id'],
          'name': units.first['name'] ?? 'وحدة افتراضية'.tr()
        };
      }
      
      return null;
    } catch (e) {
      print('خطأ في البحث عن وحدة المنتج: $e'.tr());
      return null;
    }
  }
void _loadProducts(String branchId) async {
  if (mounted) {
    setState(() {
      isLoadingProducts = true;
      selectedProducts = [];
      allProducts = [];
      selectedProduct = null;
      manuallySelectedUnitId = null;
      quantityController.clear();
      currentProductImage = null;
      _isContentVisible = true; // 🔥 تأكيد ظهور المحتوى
    });
  }

  try {
    // البحث عن الفرع المحدد في قائمة فروع المستخدم
    final selectedBranchData = branches.firstWhere(
      (branch) => branch['_id'] == branchId,
    );

    // تحميل المنتجات الخاصة بالفرع المحدد
    var token;
    await Localls.getToken().then((v) => token = v);

    final response = await http.get(
      Uri.parse('${Apiendpoints.baseUrl}${Apiendpoints.branch.getById}$branchId'),
      headers: {
        'authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(Duration(minutes: 10));

    if (response.statusCode == 200) {
      final branchData = json.decode(response.body)["data"];

      if (branchData.containsKey('productTawalf') && branchData['productTawalf'] is List) {
        final branchProducts = List<Map<String, dynamic>>.from(branchData['productTawalf']);

        // ✅ تصفية المنتجات بحيث تبقى فقط التي isTawalf = true
        final tawalfProducts = branchProducts.where((p) => p['isTawalf'] == true).toList();

        if (mounted) {
          setState(() {
            allProducts = tawalfProducts.map((product) {
              var unitInfo = _findProductUnit(product['_id']);

              return {
                '_id': product['_id'] ?? '',
                'name': product['name'] ?? 'غير معروف'.tr(),
                'bracode': product['bracode'] ?? '',
                'packSize': product['packSize']?.toString() ?? '',
                'unit': unitInfo?['name'] ?? 'غير محدد'.tr(),
                'unitId': unitInfo?['id'],
                'available': _getAvailableQuantity(product),
                'isTawalf': true, // ✅ لأننا بالفعل صفيناهم
                'packageUnit': product['packageUnit'],
              };
            }).toList();
            isLoadingProducts = false;
            _isContentVisible = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            allProducts = [];
            isLoadingProducts = false;
            _isContentVisible = true;
          });
        }
      }
    } else {
      throw Exception('فشل في تحميل بيانات الفرع: ${response.statusCode}'.tr());
    }
  } catch (error) {
    if (mounted) {
      setState(() {
        isLoadingProducts = false;
        _isContentVisible = true;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المنتجات التالفة: $error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
}
 double _getAvailableQuantity(Map<String, dynamic> product) {
    return 100;
  }

  Widget _buildUnitSelection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.withOpacity(0.2),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: manuallySelectedUnitId ?? selectedProduct?['unitId'],
        decoration: InputDecoration(
          labelText: 'اختر الوحدة'.tr(),
          labelStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: primaryColor,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: units.map((unit) {
          return DropdownMenuItem<String>(
            value: unit['_id'],
            child: Text(
              unit['name'] ?? 'غير معروف'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: primaryColor,
              ),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          if (mounted) {
            setState(() {
              manuallySelectedUnitId = newValue;
            });
          }
        },
      ),
    );
  }

  void _addProductToSelection() {
    if (currentProductImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء إضافة صورة للمنتج أولاً'.tr()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (selectedProduct == null || quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء اختيار منتج وإدخال الكمية'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double quantity = double.tryParse(quantityController.text) ?? 1;
if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الكمية يجب أن تكون أكبر من صفر'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String finalUnitId = manuallySelectedUnitId ?? selectedProduct!['unitId'];
    String finalUnitName = selectedProduct!['unit'];

    try {
      final unitData = units.firstWhere(
        (unit) => unit['_id'] == finalUnitId,
        orElse: () => {'name': finalUnitName},
      );
      finalUnitName = unitData['name'] ?? finalUnitName;
    } catch (e) {
      print('خطأ في الحصول على اسم الوحدة: $e'.tr());
    }

    bool productExists = selectedProducts.any((p) => p['_id'] == selectedProduct!['_id']);

    if (productExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('هذا المنتج مضاف مسبقاً'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        selectedProducts.add({
          '_id': selectedProduct!['_id'],
          'name': selectedProduct!['name'],
          'unit': finalUnitName,
          'unitId': finalUnitId,
          'selectedQuantity': quantity,
          'bracode': selectedProduct!['bracode'],
          'isTawalf': selectedProduct!['isTawalf'] ?? false,
          'packageUnit': selectedProduct!['packageUnit'],
          'image': currentProductImage,
        });

        selectedProduct = null;
        manuallySelectedUnitId = null;
        quantityController.clear();
        currentProductImage = null;
        _isContentVisible = true; // 🔥 تأكيد ظهور المحتوى
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إضافة المنتج بنجاح'.tr()),
        backgroundColor: primaryColor,
      ),
    );
  }

  void _removeProductFromSelection(int index) {
    if (mounted) {
      setState(() {
        selectedProducts.removeAt(index);
      });
    }
  }

  Future<void> _takePhotoForCurrentProduct() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (photo != null) {
        if (_isValidImageType(photo.path)) {
          if (mounted) {
            setState(() {
              currentProductImage = File(photo.path);
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('نوع الصورة غير مدعوم. الرجاء استخدام JPG أو PNG'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التقاط الصورة: $e'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromGalleryForCurrentProduct() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image != null) {
        if (_isValidImageType(image.path)) {
          if (mounted) {
            setState(() {
              currentProductImage = File(image.path);
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('نوع الصورة غير مدعوم. الرجاء استخدام JPG أو PNG'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الصورة: $e'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isValidImageType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return extension == 'jpg' || extension == 'jpeg' || extension == 'png';
  }

  void _removeImageFromCurrentProduct() {
    if (mounted) {
      setState(() {
        currentProductImage = null;
      });
    }
  }

  void _saveAllDamages() async {
    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء إضافة أصناف أولاً'.tr()),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (var product in selectedProducts) {
      if (product['image'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('المنتج ${product['name']} لا يحتوي على صورة'.tr()),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    for (var product in selectedProducts) {
      if (product['unitId'] == null || product['unitId'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('المنتج ${product['name']} لا يحتوي على وحدة محددة'.tr()),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      await _saveProductsIndividually();
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ البيانات: $error'.tr()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      print('خطأ مفصل: $error'.tr());
    }
  }

  Future<void> _saveProductsIndividually() async {
    if (selectedProducts.isEmpty) return;

    try {
      var token;
      await Localls.getToken().then((v) => token = v);

      int successCount = 0;
      int failedCount = 0;
      List<String> errorMessages = [];

      for (var product in selectedProducts) {
        try {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('${Apiendpoints.baseUrl}${Apiendpoints.tawalf.add}'),
          );

          request.headers['authorization'] = 'Bearer $token';

          request.fields['branch'] = selectedBranch!;
          request.fields['date'] = DateTime.now().toIso8601String();
          request.fields['product'] = product['_id'].toString();
          request.fields['qty'] = product['selectedQuantity'].toString();
          
          String unitIdToSend = '';
          
          if (product['unitId'] != null && product['unitId'].toString().isNotEmpty) {
            unitIdToSend = product['unitId'].toString();
          }
          else if (product['packageUnit'] != null && product['packageUnit'].toString().isNotEmpty) {
            unitIdToSend = product['packageUnit'].toString();
          }
          else if (units.isNotEmpty) {
            unitIdToSend = units.first['_id'].toString();
          }
          
          if (unitIdToSend.isNotEmpty) {
            request.fields['unite'] = unitIdToSend;
            print('✅ تم استخدام الوحدة: $unitIdToSend للمنتج: ${product['name']}'.tr());
          } else {
            print('⚠️ تحذير: لم يتم العثور على أي وحدة للمنتج: ${product['name']}'.tr());
            errorMessages.add('${product['name']}: لا توجد وحدة متاحة'.tr());
            failedCount++;
            continue;
          }

          if (product['image'] != null && product['image'] is File) {
            try {
              File imageFile = product['image'] as File;
              String filePath = imageFile.path;
              
              if (!_isValidImageType(filePath)) {
                errorMessages.add('${product['name']}: نوع الصورة غير مدعوم (JPG/PNG فقط)'.tr());
                failedCount++;
                continue;
              }

              final fileSize = await imageFile.length();
              if (fileSize > 5 * 1024 * 1024) {
                errorMessages.add('${product['name']}: حجم الصورة كبير جداً (5MB كحد أقصى)'.tr());
                failedCount++;
                continue;
              }

              String contentType = filePath.toLowerCase().endsWith('.png') 
                  ? 'image/png' 
                  : 'image/jpeg';

              request.files.add(
                await http.MultipartFile.fromPath(
                  'image',
                  filePath,
                  filename: 'damage_${DateTime.now().millisecondsSinceEpoch}_${product['_id']}.${contentType == 'image/png' ? 'png' : 'jpg'}',
                  contentType: MediaType.parse(contentType),
                ).timeout(Duration(minutes: 10)),
              );
              print('✅ تم إضافة صورة للمنتج: ${product['name']}'.tr());
            } catch (e) {
              print('❌ خطأ في إضافة صورة المنتج ${product['name']}: $e'.tr());
              errorMessages.add('${product['name']}: خطأ في معالجة الصورة'.tr());
              failedCount++;
              continue;
            }
          }

          print('=== بيانات المنتج المرسلة ==='.tr());
          print('product: ${request.fields['product']}');
          print('qty: ${request.fields['qty']}');
          print('branch: ${request.fields['branch']}');
          print('unite: ${request.fields['unite']}');
          print('عدد الملفات: ${request.files.length}'.tr());

          var response = await request.send().timeout(Duration(seconds: 30));
          final responseData = await response.stream.bytesToString();

          print('=== استجابة السيرفر للمنتج ${product['name']} ==='.tr());
          print('Status Code: ${response.statusCode}');
          print('Response: $responseData');

          if (response.statusCode == 200 || response.statusCode == 201) {
            successCount++;
            print('✅ تم حفظ المنتج: ${product['name']}'.tr());
          } else {
            failedCount++;
            try {
              final errorJson = json.decode(responseData);
              String errorMessage = errorJson['message'] ?? 
                                  errorJson['error'] ?? 
                                  response.statusCode.toString();
              
              if (errorMessage.toLowerCase().contains('image') || 
                  errorMessage.toLowerCase().contains('photo') ||
                  errorMessage.toLowerCase().contains('jpg') ||
                  errorMessage.toLowerCase().contains('png')) {
                errorMessage = 'خطأ في الصورة: $errorMessage'.tr();
              }
              
              errorMessages.add('${product['name']}: $errorMessage');
            } catch (e) {
              errorMessages.add('${product['name']}: ${response.statusCode} - $responseData');
            }
          }
        } catch (e) {
          failedCount++;
          String errorMsg = e.toString();
          if (errorMsg.contains('TimeoutException')) {
            errorMsg = 'انتهت مهلة الاتصال بالسيرفر'.tr();
          }
          errorMessages.add('${product['name']}: $errorMsg');
          print('❌ خطأ في حفظ المنتج ${product['name']}: $e'.tr());
        }
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (failedCount == 0) {
        if (mounted) {
          setState(() {
            selectedProducts = [];
            selectedProduct = null;
            manuallySelectedUnitId = null;
            quantityController.clear();
            currentProductImage = null;
            _isContentVisible = true;
          });
        }

    showDialog(
  context: context,
  builder: (BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFFF3F4EF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, 
                 color: Color(0xFF74826A), 
                 size: 50),
            SizedBox(height: 16),
            Text("تم الحفظ بنجاح".tr(), 
                 style: TextStyle(
                   color: Color(0xFF74826A),
                   fontSize: 18,
                   fontWeight: FontWeight.bold
                 )),
            SizedBox(height: 8),
            Text("تم حفظ جميع المنتجات بنجاح".tr()+"($successCount)",
                 style: TextStyle(color: Colors.black87),
                 textAlign: TextAlign.center),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEDBE2C), // الخلفية الذهبية
                  foregroundColor: Colors.white, // لون النص أبيض
                ),
                child: Center(child: InkWell(
                  onTap: (){Navigator.pop(context);
                  Navigator.pop(context);},
                  child: Text("موافق".tr()))),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
      } else if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ $successCount منتج وفشل $failedCount'.tr()),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );

        if (mounted) {
          setState(() {
            selectedProducts = selectedProducts.where((product) {
              return errorMessages.any((error) => error.contains(product['name']));
            }).toList();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حفظ جميع المنتجات: ${errorMessages.join(", ")}'.tr()),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }

    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ عام في الحفظ: $error'.tr()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'التوالف'.tr(),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white, size: 20),
      ),
      body: _isContentVisible ? _buildContent() : _buildLoadingContent(),
    );
  }

  // 🔥 بناء المحتوى الرئيسي بشكل منفصل
  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Branch Selection
          _buildBranchSelection(),
          SizedBox(height: 16),
          // باقي المحتوى
          _buildMainContent(),
        ],
      ),
    );
  }

  // 🔥 بناء محتوى التحميل
  Widget _buildLoadingContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          SizedBox(height: 16),
          Text(
            'جاري التحميل...'.tr(),
            style: GoogleFonts.cairo(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 بناء اختيار الفرع
  Widget _buildBranchSelection() {
    return isLoading
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'جاري تحميل فروع المستخدم...'.tr(),
                    style: GoogleFonts.cairo(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: EdgeInsets.all(2),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: selectedBranch,
                decoration: InputDecoration(
                  labelText: 'اختر الفرع'.tr(),
                  labelStyle: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: primaryColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  prefixIcon: Icon(Icons.store, color: primaryColor, size: 20),
                ),
                items: branches.map((branch) {
                  return DropdownMenuItem<String>(
                    value: branch['_id'],
                    child: Text(
                      branch['name'] ?? 'غير معروف'.tr(),
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedBranch = newValue;
                    _loadProducts(newValue!);
                  });
                },
                dropdownColor: backgroundColor,
              ),
            ),
          );
  }

  // 🔥 بناء المحتوى الرئيسي
  Widget _buildMainContent() {
    if (isLoadingProducts) {
      return Center(
        child: Column(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
            ),
            SizedBox(height: 8),
            Text(
              'جاري تحميل المنتجات التالفة...'.tr(),
              style: GoogleFonts.cairo(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (selectedBranch != null && !isLoadingProducts) {
      return Expanded(
        child: Column(
          children: [
            // قسم إضافة منتج جديد
            _buildAddProductSection(),
            SizedBox(height: 16),
            // قسم المنتجات المختارة
            _buildSelectedProductsSection(),
          ],
        ),
      );
    } else if (selectedBranch == null && !isLoading) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store, size: 60, color: accentColor),
              SizedBox(height: 16),
              Text(
                'الرجاء اختيار الفرع أولاً'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'سيتم عرض المنتجات التالفة الخاصة بالفرع بعد الاختيار'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      return Expanded(child: Container());
    }
  }

  // 🔥 بناء قسم إضافة المنتج
  Widget _buildAddProductSection() {
    return Card(
      elevation: 2,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle, color: primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'إضافة منتج تالف'.tr(),
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (selectedProduct != null && selectedProduct!['unitId'] == null) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'هذا المنتج لا يحتوي على وحدة محددة، الرجاء اختيار وحدة:'.tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildUnitSelection(),
              ),
              SizedBox(height: 16),
            ],
            
            _buildProductSelectionRow(),
            SizedBox(height: 16),
            _buildImageSection(),
            SizedBox(height: 16),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

// 🔥 بناء صف اختيار المنتج (تصميم مضغوط)
Widget _buildProductSelectionRow() {
  return Column(
    children: [
      Row(
        children: [
          // اختيار المنتج
          Expanded(
            flex: 8,
            child: Container(
                            height: 45,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.withOpacity(0.2)
              ),
              child: DropdownButtonFormField<Map<String, dynamic>>(
                isExpanded: true,
                initialValue: selectedProduct,
                decoration: InputDecoration(
                  labelText: "اسم المنتج".tr(),
                  labelStyle: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: primaryColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: allProducts.map((product) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: product,
                    child: Text(
                      product['name'],
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: primaryColor,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedProduct = newValue;
                    manuallySelectedUnitId = newValue?['unitId'];
                  });
                },
                dropdownColor: backgroundColor,
              ),
            ),
          ),
          SizedBox(width: 8),
          
        
          
          // حقل الكمية
          Expanded(
            flex: 4,
            child: Container(
                            height: 45,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.withOpacity(0.2)
              ),
              child: TextField(
                
                controller: quantityController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
                decoration: InputDecoration(
                
                  hintText: "0",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),
                    SizedBox(width: 2),

            // عرض الوحدة
          Expanded(
            flex: 3,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.withOpacity(0.1),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    
                    'الوحدة'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: MediaQuery.of(context).size.width*0.019,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    selectedProduct != null && selectedProduct!['unit'] != null 
                      ? selectedProduct!['unit']
                      : '--',
                    style: GoogleFonts.cairo(
                      
                      fontSize: MediaQuery.of(context).size.width*0.026,
                      fontWeight: FontWeight.bold,
                      color: selectedProduct != null && selectedProduct!['unit'] != null 
                        ? primaryColor 
                        : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          
          // زر الكاميرا
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20)
            ),
            child: IconButton(
              onPressed: _takePhotoForCurrentProduct,
              icon: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      
      // اختيار الوحدة يدوياً إذا لزم الأمر
      if (selectedProduct != null && selectedProduct!['unitId'] == null) ...[
        SizedBox(height: 12),
        _buildUnitSelection(),
      ],
    ],
  );
}  // 🔥 بناء قسم الصورة
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, size: 20, color: primaryColor),
            SizedBox(width: 8),
            Text(
              "صورة المنتج :".tr(),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (currentProductImage == null)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الصورة مطلوبة لإضافة المنتج'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (currentProductImage != null)
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(currentProductImage!, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 2,
                left: 2,
                child: GestureDetector(
                  onTap: _removeImageFromCurrentProduct,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // 🔥 بناء زر الإضافة
  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(Icons.add, size: 18),
        label: Text('إضافة المنتج'.tr(), style: GoogleFonts.cairo(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: (selectedProduct != null && 
              (selectedProduct!['unitId'] != null || manuallySelectedUnitId != null) &&
              currentProductImage != null)
              ? secondaryColor 
              : Colors.grey,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: (selectedProduct != null && 
            (selectedProduct!['unitId'] != null || manuallySelectedUnitId != null) &&
            currentProductImage != null)
            ? _addProductToSelection 
            : null,
      ),
    );
  }

  // 🔥 بناء قسم المنتجات المختارة
  Widget _buildSelectedProductsSection() {
    if (selectedProducts.isEmpty) {
      if (allProducts.isEmpty) {
        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 60, color: accentColor),
                SizedBox(height: 16),
                Text(
                  'لا توجد منتجات تالفة في هذا الفرع'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'الفرع المحدد لا يحتوي على منتجات تالفة مسجلة'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return Container();
    }

    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                "المنتجات المختارة".tr()+"(${selectedProducts.length})",
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: Card(
              elevation: 2,
              color: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: selectedProducts.length,
                        itemBuilder: (context, index) {
                          final product = selectedProducts[index];
                          final image = product['image'] as File?;
                          bool hasUnit = product['unitId'] != null;
                          bool hasImage = image != null;

                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: (hasUnit && hasImage) ? 
                                primaryColor.withOpacity(0.05) : 
                                Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (hasUnit && hasImage) ? 
                                  primaryColor.withOpacity(0.3) : 
                                  Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: ListTile(
                              leading: _buildProductImage(image, hasImage),
                              title: Text(
                                product['name'],
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: (hasUnit && hasImage) ? primaryColor : Colors.red,
                                ),
                              ),
                              subtitle: _buildProductSubtitle(product, hasUnit, hasImage),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _removeProductFromSelection(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 بناء صورة المنتج
  Widget _buildProductImage(File? image, bool hasImage) {
    if (image != null) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: primaryColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(image, fit: BoxFit.cover),
        ),
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red),
        ),
        child: Icon(Icons.no_photography, color: Colors.red, size: 20),
      );
    }
  }

  // 🔥 بناء الوصف الفرعي للمنتج
  Widget _buildProductSubtitle(Map<String, dynamic> product, bool hasUnit, bool hasImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "الكمية".tr()+":"+"${product['selectedQuantity']} ${product['unit']}",
          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
        ),
        if (!hasImage) Text('⚠️ لا توجد صورة'.tr(), style: GoogleFonts.cairo(fontSize: 10, color: Colors.red)),
        if (!hasUnit) Text('⚠️ لا توجد وحدة محددة'.tr(), style: GoogleFonts.cairo(fontSize: 10, color: Colors.red)),
      ],
    );
  }

  // 🔥 بناء زر الحفظ
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: _saveAllDamages,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "حفظ".tr()+"(${selectedProducts.length})",
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}