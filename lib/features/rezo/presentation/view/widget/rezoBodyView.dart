import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/utils/localls.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:http_parser/http_parser.dart';
import '../../../../../core/utils/apiEndpoints.dart';
import 'package:flutter/material.dart' as flutter;

class Rezobodyview extends StatefulWidget {
  @override
  _RezobodyviewState createState() => _RezobodyviewState();
}

class _RezobodyviewState extends State<Rezobodyview> {
  String? selectedBranch;
  String? selectedDeliveryApp;
  List<Map<String, dynamic>> branches = [];
  List<Map<String, dynamic>> deliveryApps = [];
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> units = [];
  List<Map<String, dynamic>> selectedProducts = [];
  bool isLoading = false;
  bool isLoadingProducts = false;
  bool isLoadingUnits = false;
  bool isLoadingDeliveryApps = false;
  File? _selectedImage;

  final Color primaryColor = Color(0xFF74826A);
  final Color secondaryColor = Color(0xFFEDBE2C);
  final Color accentColor = Color(0xFFCDBCA2);
  final Color backgroundColor = Color(0xFFF3F4EF);

  // متغيرات لإدارة كميات المنتجات في الـ Grid
  Map<String, int> productQuantities = {};

  @override
  void initState() {
    super.initState();
    selectedProducts = [];
    _loadUserBranches();
    _loadUnits();
    _loadAllProducts();
    _loadDeliveryApps();
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
        Uri.parse('${Apiendpoints.baseUrl}${Apiendpoints.auth.userBranchRezoCasher}'),
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
              
              // 🔥 إذا كان هناك فرع واحد فقط، اختياره تلقائياً
              if (branches.length == 1) {
                selectedBranch = branches.first['_id'];
              }
              
              isLoading = false;
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

  // 🔥 دالة جديدة لتحميل تطبيقات التوصيل
  Future<void> _loadDeliveryApps() async {
    if (mounted) {
      setState(() {
        isLoadingDeliveryApps = true;
      });
    }

    try {
      var token;
      await Localls.getToken().then((v) => token = v);

      final response = await http.get(
        Uri.parse('${Apiendpoints.baseUrl}${Apiendpoints.deliveryApp.getAll}'),
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
              deliveryApps = List<Map<String, dynamic>>.from(data);
              if (deliveryApps.isNotEmpty) {
                selectedDeliveryApp = deliveryApps.first['_id'];
              }
              isLoadingDeliveryApps = false;
            });
          }
        } else {
          print('هيكل بيانات تطبيقات التوصيل غير متوقع: $data');
          throw Exception('هيكل بيانات تطبيقات التوصيل غير متوقع'.tr());
        }
      } else {
        throw Exception('فشل في تحميل تطبيقات التوصيل: ${response.statusCode}'.tr());
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoadingDeliveryApps = false;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحميل تطبيقات التوصيل: ${error.toString()}'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  // 🔥 دالة جديدة لتحميل جميع المنتجات من API الجديدة
  Future<void> _loadAllProducts() async {
    if (mounted) {
      setState(() {
        isLoadingProducts = true;
      });
    }

    try {
      var token;
      await Localls.getToken().then((v) => token = v);

      final response = await http.get(
        Uri.parse('${Apiendpoints.baseUrl}${Apiendpoints.rezoProductCasher.getAll}'),
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
              allProducts = List<Map<String, dynamic>>.from(data).map((product) {
                return {
                  '_id': product['_id'] ?? '',
                  'name': product['name'] ?? 'غير معروف'.tr(),
                  'price': product['price'] ?? 0,
                  'createdAt': product['createdAt'] ?? '',
                  'updatedAt': product['updatedAt'] ?? '',
                  'bracode': product['bracode'] ?? '',
                  'packSize': product['packSize']?.toString() ?? '',
                  'unit': 'وحدة'.tr(),
                  'unitId': null,
                  'available': 100,
                  'isTawalf': true,
                  'packageUnit': null,
                };
              }).toList();
              
              // تهيئة الكميات لكل منتج
              for (var product in allProducts) {
                productQuantities[product['_id']] = 0;
              }
              
              isLoadingProducts = false;
            });
          }
        } else {
          print('هيكل بيانات المنتجات غير متوقع: $data');
          throw Exception('هيكل بيانات المنتجات غير متوقع'.tr());
        }
      } else {
        throw Exception('فشل في تحميل المنتجات: ${response.statusCode}'.tr());
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoadingProducts = false;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحميل المنتجات: ${error.toString()}'.tr()),
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

  void _onBranchSelected(String branchId) {
    if (mounted) {
      setState(() {
        selectedBranch = branchId;
        selectedProducts = [];
        for (var product in allProducts) {
          productQuantities[product['_id']] = 0;
        }
      });
    }
  }

  void _onDeliveryAppSelected(String deliveryAppId) {
    if (mounted) {
      setState(() {
        selectedDeliveryApp = deliveryAppId;
      });
    }
  }

  void _increaseQuantity(String productId) {
    setState(() {
      productQuantities[productId] = (productQuantities[productId] ?? 0) + 1;
    });
  }

  void _decreaseQuantity(String productId) {
    setState(() {
      int currentQuantity = productQuantities[productId] ?? 0;
      if (currentQuantity > 0) {
        productQuantities[productId] = currentQuantity - 1;
      }
    });
  }

  void _addProductToSelection(Map<String, dynamic> product) {
    int quantity = productQuantities[product['_id']] ?? 0;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الكمية يجب أن تكون أكبر من صفر'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء اختيار الفرع أولاً'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Map<String, dynamic>? unitData = _findProductUnit(product['_id']);
    String finalUnitId = unitData?['id'];
    String finalUnitName = unitData?['name'] ?? 'وحدة'.tr();

    bool productExists = selectedProducts.any((p) => p['_id'] == product['_id']);

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
          '_id': product['_id'],
          'name': product['name'],
          'unit': finalUnitName,
          'unitId': finalUnitId,
          'selectedQuantity': quantity.toInt(),
          'bracode': product['bracode'],
          'isTawalf': true,
          'packageUnit': product['packageUnit'],
          'price': product['price'],
        });

        productQuantities[product['_id']] = 0;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم إضافة المنتج بنجاح".tr()+ " - " +product['name']),
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

  // 🔥 دالة لحساب الإجمالي
  double _calculateTotal() {
    double total = 0;
    for (var product in selectedProducts) {
      double price = (product['price'] ?? 0).toDouble();
      int quantity = product['selectedQuantity'] ?? 0;
      total += price * quantity;
    }
    return total;
  }

  int _calculateTotalQty() {
    int total = 0;

    for (var product in selectedProducts) {
      int quantity = 0;

      if (product['selectedQuantity'] != null) {
        quantity = int.tryParse(product['selectedQuantity'].toString()) ?? 0;
      }

      total += quantity;
    }

    return total;
  }

  // 🔥 دالة للتحقق من نوع الصورة - محدثة لتدعم فقط JPG و PNG
  bool _isImageSupported(File image) {
    try {
      String extension = image.path.split('.').last.toLowerCase();
      return extension == 'jpg' || extension == 'jpeg' || extension == 'png';
    } catch (e) {
      return false;
    }
  }

  // 🔥 دالة لعرض رسالة خطأ نوع الصورة - محدثة
  void _showImageFormatError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('يجب أن تكون الصورة بصيغة JPG أو PNG فقط'.tr()),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  // 🔥 دالة الحفظ الرئيسية - محدثة وفقاً للـ Schema
  Future<void> _saveProductsWithImageValidation() async {
    if (selectedProducts.isEmpty) return;

    // 🔥 التحقق من وجود الصورة (إجباري)
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الصورة إجبارية، الرجاء التقاط صورة الفاتورة'.tr()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    try {
      var token;
      await Localls.getToken().then((v) => token = v);

      // 🔥 التصحيح: إنشاء مصفوفة الـ items بالشكل الصحيح الذي يتوقعه السيرفر
      List<Map<String, dynamic>> items = selectedProducts.map((product) {
        return {
          "product": product['_id'],  // ✅ يجب أن يكون ObjectId
          "qty": product['selectedQuantity']  // ✅ يجب أن يكون رقم صحيح
        };
      }).toList();

      print('=== بيانات الطلب المرسلة ==='.tr());
      print('عدد العناصر في item: ${items.length}');
      print('العناصر: ${json.encode(items)}');
      print('الفرع: $selectedBranch');
      print('تطبيق التوصيل: $selectedDeliveryApp');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Apiendpoints.baseUrl}${Apiendpoints.rezoCasher.add}'),
      );

      request.headers['authorization'] = 'Bearer $token';

      print(items);
      // 🔥 إضافة الحقول بشكل صحيح
      request.fields['branch'] = selectedBranch!;
      request.fields['deliveryApp'] = selectedDeliveryApp!;
      request.fields['item'] = jsonEncode(items);  // درست على السيرفر

      // 🔥 إضافة صورة الفاتورة (إجباري)
      String extension = _selectedImage!.path.split('.').last.toLowerCase();
      String mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
      
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _selectedImage!.path,
        contentType: MediaType.parse(mimeType),
      ));
      
      print('✅ تم إضافة الصورة بصيغة مدعومة: ${_selectedImage!.path}'.tr());

      var response = await request.send().timeout(Duration(seconds: 30));
      final responseData = await response.stream.bytesToString();

      print('=== استجابة السيرفر ==='.tr());
      print('Status Code: ${response.statusCode}');
      print('Response: $responseData');
      print(items[0]["product"]);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // نجاح الحفظ
        if (mounted) {
          setState(() {
            selectedProducts = [];
            _selectedImage = null;
            for (var product in allProducts) {
              productQuantities[product['_id']] = 0;
            }
          });
        }

        _showSuccessDialog();
      } else {
        // فشل الحفظ
        final errorJson = json.decode(responseData);
        String errorMessage = errorJson['message'] ?? 
                            errorJson['error'] ?? 
                            'فشل في حفظ البيانات'.tr();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $errorMessage'.tr()),
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
      
      String errorMsg = error.toString();
      if (errorMsg.contains('TimeoutException')) {
        errorMsg = 'انتهت مهلة الاتصال بالسيرفر'.tr();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الحفظ: $errorMsg'.tr()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      print('خطأ مفصل: $error'.tr());
    }
  }

  // 🔥 دالة بديلة باستخدام JSON مباشرة (إذا استمرت المشكلة)
  Future<void> _saveWithJsonRequest() async {
    if (selectedProducts.isEmpty) return;

    // 🔥 التحقق من وجود الصورة (إجباري)
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الصورة إجبارية، الرجاء التقاط صورة الفاتورة'.tr()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    try {
      var token;
      await Localls.getToken().then((v) => token = v);

      // 🔥 إنشاء البيانات بالشكل الصحيح
      List<Map<String, dynamic>> items = selectedProducts.map((product) {
        return {
          "product": product['_id'],
          "qty": product['selectedQuantity']
        };
      }).toList();

      Map<String, dynamic> requestBody = {
        "item": items,
        "branch": selectedBranch,
        "deliveryApp": selectedDeliveryApp,
      };

      print('=== طلب JSON المرسل ==='.tr());
      print('البيانات: ${json.encode(requestBody)}');

      var response = await http.post(
        Uri.parse('${Apiendpoints.baseUrl}${Apiendpoints.rezoCasher.add}'),
        headers: {
          'authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('=== استجابة السيرفر ==='.tr());
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            selectedProducts = [];
            _selectedImage = null;
            for (var product in allProducts) {
              productQuantities[product['_id']] = 0;
            }
          });
        }
        _showSuccessDialog();
      } else {
        final errorJson = json.decode(response.body);
        String errorMessage = errorJson['message'] ?? 'فشل في حفظ البيانات'.tr();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $errorMessage'.tr()),
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
          content: Text('خطأ في الحفظ: ${error.toString()}'.tr()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // 🔥 دالة التقاط الصورة
  Future<void> _takePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        File originalImage = File(pickedFile.path);

        if (!_isImageSupported(originalImage)) {
          _showImageFormatError();
          return;
        }

        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final compressedPath = '${tempDir.path}/compressed_$timestamp.jpg';

        try {
          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            originalImage.path,
            compressedPath,
            format: CompressFormat.jpeg,
            quality: 85,
            minWidth: 600,
            minHeight: 400,
          );

          if (compressedFile != null) {
            if (mounted) {
              setState(() {
                _selectedImage = File(compressedFile.path);
              });
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم التقاط صورة الفاتورة بنجاح'.tr()),
                backgroundColor: primaryColor,
              ),
            );
          } else {
            throw Exception('فشل في ضغط الصورة');
          }
        } catch (compressError) {
          print('خطأ في ضغط الصورة: $compressError');
          if (mounted) {
            setState(() {
              _selectedImage = originalImage;
            });
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم التقاط الصورة باستخدام الصورة الأصلية'.tr()),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('خطأ في التقاط الصورة: $e'.tr());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التقاط الصورة: ${e.toString()}'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryColor),
                title: Text('التقاط صورة'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
             
              if (_selectedImage != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('حذف الصورة'.tr()),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم حذف الصورة'.tr()),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _saveAllDamages() async {
    if (selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء اختيار الفرع أولاً'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedDeliveryApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء اختيار تطبيق التوصيل أولاً'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    // 🔥 التحقق من وجود الصورة (إجباري)
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الصورة إجبارية، الرجاء التقاط صورة الفاتورة أولاً'.tr()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
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

    if (_selectedImage != null && !_isImageSupported(_selectedImage!)) {
      _showImageFormatError();
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // جرب الطريقة الأولى (Multipart)
      await _saveProductsWithImageValidation();
      
      // إذا فشلت الطريقة الأولى، جرب الطريقة البديلة
      // await _saveWithJsonRequest();
      
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

  void _showSuccessDialog() {
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
                Text("تم حفظ جميع المنتجات بنجاح".tr(),
                     style: TextStyle(color: Colors.black87),
                     textAlign: TextAlign.center),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEDBE2C),
                      foregroundColor: Colors.white,
                    ),
                    child: Text("موافق".tr()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "ريزو كاشير".tr(),
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
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSelectionRow(),
          SizedBox(height: 16),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  // 🔥 بناء صف الاختيارات (الفروع + تطبيقات التوصيل)
  Widget _buildSelectionRow() {
    return Row(
      children: [
        // الفروع
        Expanded(
          child: _buildBranchSelection(),
        ),
        SizedBox(width: 12),
        // تطبيقات التوصيل
        Expanded(
          child: _buildDeliveryAppSelection(),
        ),
      ],
    );
  }

  Widget _buildBranchSelection() {
    // 🔥 إذا كان هناك فرع واحد فقط، لا نعرض Dropdown
    if (branches.length == 1) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.store, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  branches.first['name'] ?? 'غير معروف'.tr(),
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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

    return isLoading
        ? _buildLoadingCard('جاري تحميل فروع المستخدم...'.tr())
        : Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: EdgeInsets.all(2),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedBranch,
                decoration: InputDecoration(
                  labelText: 'اختر الفرع'.tr(),
                  labelStyle: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  _onBranchSelected(newValue!);
                },
                dropdownColor: backgroundColor,
              ),
            ),
          );
  }

  Widget _buildDeliveryAppSelection() {
    return isLoadingDeliveryApps
        ? _buildLoadingCard('جاري تحميل تطبيقات التوصيل...'.tr())
        : Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: EdgeInsets.all(2),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedDeliveryApp,
                decoration: InputDecoration(
                  labelText: "تطبيق التوصيل".tr(),
                  labelStyle: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    fontSize: MediaQuery.of(context).size.width*0.028,
                    color: primaryColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  prefixIcon: Icon(Icons.delivery_dining, color: primaryColor, size: 20),
                ),
                items: deliveryApps.map((app) {
                  return DropdownMenuItem<String>(
                    value: app['_id'],
                    child: Text(
                      app['name'] ?? 'غير معروف'.tr(),
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  _onDeliveryAppSelected(newValue!);
                },
                dropdownColor: backgroundColor,
              ),
            ),
          );
  }

  Widget _buildLoadingCard(String text) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.cairo(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 بناء المحتوى الرئيسي
  Widget _buildMainContent() {
    if (isLoadingProducts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
            ),
            SizedBox(height: 8),
            Text(
              "جاري تحميل المنتجات...".tr(),
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

    // 🔥 إذا كان هناك فرع واحد فقط وتم اختياره تلقائياً، أو تم اختيار فرع يدوياً
    if ((branches.length == 1 && selectedBranch != null) || (selectedBranch != null && !isLoadingProducts)) {
      return Column(
        children: [
          // قسم عرض المنتجات في Grid
          Expanded(
            flex: 3,
            child: _buildProductsGridSection(),
          ),
          SizedBox(height: 16),
          // قسم المنتجات المختارة
          _buildSelectedProductsSection(),
        ],
      );
    } else if (selectedBranch == null && !isLoading) {
      return Center(
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
              'سيتم عرض المنتجات بعد اختيار الفرع'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  // 🔥 بناء قسم عرض المنتجات في Grid
  Widget _buildProductsGridSection() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2, color: primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              "المنتجات".tr()+ " "+"(${allProducts.length})",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Expanded(
          child: Card(
            elevation: 2,
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _getCrossAxisCount(context),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.1,
                  mainAxisExtent: 115, 
                ),
                itemCount: allProducts.length,
                itemBuilder: (context, index) {
                  final product = allProducts[index];
                  final productId = product['_id'];
                  final quantity = productQuantities[productId] ?? 0;
                  final hasQuantity = quantity > 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: hasQuantity ? 
                        primaryColor.withOpacity(0.05) : 
                        Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasQuantity ? 
                          primaryColor : 
                          Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (product['price'] != null && product['price'] > 0)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: secondaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${product['price']} ',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryColor,
                                ),
                              ),
                            ),
                          ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1, vertical: 8),
                              child: Text(
                                product['name'],
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // زر الناقص
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: quantity > 0 ? Colors.red : Colors.grey,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(Icons.remove, size: 12, color: Colors.white),
                                            onPressed: () => _decreaseQuantity(productId),
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        
                                        // عرض الكمية
                                        Container(
                                          constraints: BoxConstraints(minWidth: 30),
                                          height: 24,
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: primaryColor),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Center(
                                            child: Text(
                                              quantity.toString(),
                                              style: GoogleFonts.cairo(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        
                                        // زر الزائد
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(Icons.add, size: 12, color: Colors.white),
                                            onPressed: () => _increaseQuantity(productId),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    
                                    // زر الإضافة
                                    Container(
                                      height: 24,
                                      margin: EdgeInsets.symmetric(horizontal: 4),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: hasQuantity ? secondaryColor : Colors.grey,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        onPressed: hasQuantity
                                            ? () => _addProductToSelection(product)
                                            : null,
                                        child: Text(
                                          "اضافة".tr(),
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }

  Widget _buildSelectedProductsSection() {
    double totalAmount = _calculateTotal();
    int totalQty =_calculateTotalQty();
    
    if (selectedProducts.isEmpty) {
      return Container(
        height: 80,
        child: Card(
          elevation: 2,
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 30, color: accentColor),
                SizedBox(height: 8),
                Text(
                  "لم يتم اضافة صنف".tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: 408,
        minHeight: 100,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                "المنتجات المختارة".tr() + " ( ${selectedProducts.length} )",
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
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    // رأس الجدول
                    Container(
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: Text(
                                'الصنف'.tr(),
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: Text(
                                'الكمية'.tr(),
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: Text(
                                'السعر'.tr(),
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: Text(
                                'إجراءات'.tr(),
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // محتوى الجدول
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: selectedProducts.length,
                        itemBuilder: (context, index) {
                          final product = selectedProducts[index];
                          bool hasUnit = product['unitId'] != null;
                          int totalPrice = (product['price'] ?? 0) * (product['selectedQuantity'] ?? 0);
                          int? totalqty = 0;

                          return Container(
                            height: 37,
                            margin: EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: hasUnit ? 
                                primaryColor.withOpacity(0.05) : 
                                Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: hasUnit ? 
                                  primaryColor.withOpacity(0.3) : 
                                  Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                // اسم المنتج
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 1, horizontal: 7),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product['name'],
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: hasUnit ? primaryColor : Colors.red,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // الكمية
                                Expanded(
                                  child: Directionality(
                                    textDirection: flutter.TextDirection.rtl,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                      child: Text(
                                        "${product['selectedQuantity']}",
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                                    child: Text(
                                      product['price'] != null && product['price'] > 0 
                                        ? "${(totalPrice.toStringAsFixed(0))}"
                                        : "-",
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        color: secondaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20,),

                                // زر الحذف
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.delete, color: Colors.red, size: 18),
                                      onPressed: () => _removeProductFromSelection(index),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // 🔥 قسم الإجمالي وصورة الفاتورة
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          // صف الإجمالي
                          Row(
                            children: [
                              
                              Text(
                                'الإجمالي:'.tr(),
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              Spacer(
                                flex: 2,
                              ),
                              Text(
                                '       ${totalQty}                 ${totalAmount.toStringAsFixed(0)} ',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryColor,
                                ),
                              ), Spacer(
                                flex: 2,
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          
                          // 🔥 تحذير الصورة الإجبارية
                          if (_selectedImage == null)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(8),
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
                                      'الصورة إجبارية'.tr(),
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          SizedBox(height: 12),
                          
                          // صف الأزرار
                          Row(
                            children: [
                              // زر إضافة صورة الفاتورة
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedImage != null ? secondaryColor : Colors.red,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(45, 45),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                ),
                                onPressed: _showImageOptions,
                                child: Icon(
                                  _selectedImage != null ? Icons.check : Icons.camera_alt,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 5),
                              
                              // زر الحفظ
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(double.infinity, 45),
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
                                            Icon(Icons.save, color: Colors.white, size: 18),
                                            SizedBox(width: 6),
                                            Text(
                                              "حفظ".tr()+"(${selectedProducts.length})",
                                              style: GoogleFonts.cairo(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}