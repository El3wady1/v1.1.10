import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saladafactory/core/Widgets/showsnackbar.dart';
import 'package:saladafactory/core/app_router.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:saladafactory/core/utils/styles.dart';
import 'package:saladafactory/features/home/presentation/view/widget/succesView.dart';
import 'package:saladafactory/features/in/data/services/addTrancWhenNewServices.dart';
import 'package:saladafactory/features/in/data/services/makeINTracwhenaddServices.dart';
import 'package:saladafactory/features/in/data/services/searchProductByBarcode.dart';
import 'package:saladafactory/features/in/presentation/view/widget/customINTextFormFeild.dart';
import 'package:saladafactory/features/in/presentation/view/widget/displayExistProduct.dart';
import 'package:saladafactory/features/in/presentation/view/widget/fatwraaView.dart';
import 'package:saladafactory/features/in/presentation/view/widget/unitDropBox.dart';
import 'package:saladafactory/features/out/presentation/view/widget/acceptedDropBox.dart';
import 'package:saladafactory/features/scanBarCode/presentation/view/scanbarCodeView.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../../data/services/makeINTransactionNew.dart';

class InviewBodyView extends StatefulWidget {
  final String? initialBarcode;
  final bool isExist;
  final String productID;
  final String userID;
  final String unit;
  final String department;
  final String supplier;
  final dynamic mainProduct;
  final List<dynamic> SupplierData;
  final List<dynamic> unitData;
  final bool canAddPernew;

  const InviewBodyView({
    super.key,
    this.initialBarcode,
    required this.isExist,
    required this.productID,
    required this.unit,
    required this.department,
    required this.supplier,
    required this.userID,
    required this.SupplierData,
    required this.unitData,
    required this.mainProduct,
    required this.canAddPernew,
  });

  @override
  State<InviewBodyView> createState() => _InviewBodyViewState();
}

class _InviewBodyViewState extends State<InviewBodyView> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final TextEditingController name = TextEditingController();
  final TextEditingController qty = TextEditingController();
  final TextEditingController packSize = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController expireDate = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  
  bool isloading = false;
  String itemName = '';
  String quantity = '';
  String? unitvalue;
  String? supvalue;
  String? _currentBarcode;
  bool _isLoading = false;
  bool isProductExist = false;
  bool _showInvoice = false;
  bool _initialLoadComplete = false;

  int selectedsupIndex = 0;
  int selectedunitIndex = 0;

  late List<String> names;
  late List<String> suppliersIds;
  late List<String> unitnames;
  late List<String> unitIDlist;

  Map<String, dynamic>? uploadedItem;

  @override
  void initState() {
    super.initState();
    _currentBarcode = widget.initialBarcode ?? '';
    isProductExist = widget.isExist;
    _initializeDropdownData();
    if (_currentBarcode!.isNotEmpty) {
      barcodeController.text = _currentBarcode!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _initialLoadComplete = true;
      });
    });
  }

  void _initializeDropdownData() {
    names = widget.SupplierData.map(
        (item) => item['name']?.toString() ?? 'مورد غير معروف').toList();
    suppliersIds =
        widget.SupplierData.map((item) => item['_id']?.toString() ?? '')
            .toList();

    unitnames = widget.unitData
        .map((item) => item['name']?.toString() ?? 'وحدة غير معروفة')
        .toList();
    unitIDlist =
        widget.unitData.map((item) => item['_id']?.toString() ?? '').toList();

    if (names.isNotEmpty) {
      supvalue = names.first;
    }
    if (unitnames.isNotEmpty) {
      unitvalue = unitnames.first;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF74826A),
                onPrimary: Colors.white,
                onSurface: Color(0xFF74826A),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF74826A),
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        expireDate.text = picked.toIso8601String();
      });
    }
  }

  Future<void> uploadItem() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_currentBarcode == null || _currentBarcode!.isEmpty) {
      showfalseSnackBar(context: context, message: 'يجب مسح الباركود أولاً', icon: Icons.dangerous);
      return;
    }

    if (name.text.trim().isEmpty) {
      showfalseSnackBar(context: context, message: 'اسم الصنف مطلوب', icon: Icons.dangerous);
      return;
    }

    if (unitvalue == null || unitvalue!.isEmpty) {
      showfalseSnackBar(context: context, message: 'يجب اختيار وحدة القياس', icon: Icons.dangerous);
      return;
    }

    if (supvalue == null || supvalue!.isEmpty) {
      showfalseSnackBar(context: context, message: 'يجب اختيار المورد', icon: Icons.dangerous);
      return;
    }

    setState(() {
      isloading = true;
      _isLoading = true;
    });

    try {
      var userID = await Localls.getUserID();
      var departmentID = await Localls.getdepartment();

      Map<String, dynamic> item = {
        'name': name.text,
        'quantity': qty.text.isEmpty ? '0' : qty.text,
        'packSize': packSize.text.isEmpty ? '0' : packSize.text,
        'price': price.text.isEmpty ? '0' : price.text,
        'expireDate': expireDate.text.isEmpty
            ? DateTime.now().add(const Duration(days: 365)).toIso8601String()
            : expireDate.text,
        'unitID': unitIDlist.isNotEmpty ? unitIDlist[selectedunitIndex] : '',
        'supplierID':
            suppliersIds.isNotEmpty ? suppliersIds[selectedsupIndex] : '',
        'barcode': _currentBarcode!,
        'productID': widget.productID,
        'unitName': unitvalue ?? 'وحدة غير معروفة',
        'supplierName': supvalue ?? 'مورد غير معروف',
        'date': DateTime.now().toIso8601String(),
        'scanned': true,
      };

      await makeINTransactionwhenNoproductAdd(
        productID: widget.productID,
        quantity: double.parse(item['quantity']),
        userID: userID.toString(),
        unitID: item['unitID'],
        departmentID: departmentID.toString(),
        supplier: item['supplierID'],
        context: context,
        name: item['name'],
        bracode: item['barcode'],
        supplierID: item['supplierID'],
        packSize: item['packSize'],
        price: item['price'],
        expireDate: item['expireDate'],
        mainProduct: widget.mainProduct,
      );

      if (mounted) {
        setState(() {
          uploadedItem = item;
          _showInvoice = true;
        });
    await   ServiceIN.addInTransactionNew(productID:widget.productID.toString(), userID: userID.toString(), context: context);
    
      }
    } catch (e) {
      if (mounted) {
        showfalseSnackBar(
          context: context,
          message: 'خطأ أثناء الرفع: ${e.toString()}', 
          icon: Icons.dangerous,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isloading = false;
          _isLoading = false;
        });
      }
    }
  }

  void closeInvoice() {
    setState(() {
      _showInvoice = false;
      uploadedItem = null;
      Navigator.pop(context);
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} - ${dateTime.hour}:${dateTime.minute}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!_initialLoadComplete) {
      return const Center(child: CircularProgressIndicator());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ModalProgressHUD(
        color: Colors.black,
        opacity: 0.6,
        inAsyncCall: isloading,
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F4EF),
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios),
              color: const Color(0xFF74826A),
            ),
            title: Text(
              (isProductExist
                  ? "صنف"
                  : widget.canAddPernew
                      ? "صنف جديد"
                      : "انتبه"),
              style: TextAppStyles.apparblackstyle.copyWith(
                color: const Color(0xFF74826A),
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: const Color(0xFFF3F4EF),
          ),
          body: _showInvoice
              ? _buildInvoice(context)
              : _buildMainContent(context, theme),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          children: [
            if (!isProductExist) ...[
              if (!widget.canAddPernew) ...[
                _buildNotAllowedView()
              ] else ...[
                _buildNewProductForm()
              ]
            ] else ...[
              _buildExistingProductView()
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotAllowedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                textAlign: TextAlign.center,
                "رواجع المسئول \n غير مسموح لك بالاضافه",
                style: GoogleFonts.cairo(),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNewProductForm() {
    return Column(
      children: [
        Customintextformfeild(
          controller: name,
          label: 'اسم الصنف *',
          icon: Icons.inventory,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'اسم الصنف مطلوب';
            }
            return null;
          },
          onSaved: (value) => itemName = value ?? '',
          scrollController: _scrollController,
        ),
        const SizedBox(height: 16),
        _buildBarcodeField(),
        const SizedBox(height: 16),
        Customintextformfeild(
          controller: packSize,
          label: 'حجم العبوة',
          icon: Icons.scale,
          scrollController: _scrollController,
          validator: null,
        ),
        const SizedBox(height: 16),
        Unitdropbox(
          label: 'اختر وحدة القياس *',
          icon: Icons.location_city,
          items: unitnames,
          value: unitvalue,
          onChanged: (value) {
            setState(() {
              unitvalue = value;
              selectedunitIndex = unitnames.indexOf(value!);
            });
          },
        ),
        // const SizedBox(height: 16),
        // _buildSupplierDropdown(),
        const SizedBox(height: 20),
        _buildSubmitButton(),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildBarcodeField() {
    return TextFormField(
      controller: barcodeController,
      decoration: InputDecoration(
        labelText: 'باركود المنتج *',
        hintText: 'اضغط لمسح الباركود',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: const Icon(Icons.qr_code_scanner),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value!.isEmpty ? 'يجب مسح الباركود' : null,
      onSaved: (value) => _currentBarcode = value,
      readOnly: true,
      onTap: () async {
        try {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => ScanBarcodeView(mainProduct: widget.mainProduct),
            ),
          );

          if (result != null && result.isNotEmpty) {
            setState(() {
              barcodeController.text = result;
              _currentBarcode = result;
            });
          }
        } catch (e) {
          debugPrint('Error during barcode scanning: $e');
        }
      },
    );
  }

  Widget _buildSupplierDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'اختر المورد *',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      initialValue: supvalue,
      items: names.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          supvalue = value;
          selectedsupIndex = names.indexOf(value!);
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يجب اختيار المورد';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : uploadItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF74826A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.upload,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'رفع الصنف',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildExistingProductView() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Displayexistproduct(barcode: _currentBarcode ?? ""),
    );
  }

  Widget _buildInvoice(BuildContext context) {
    if (uploadedItem == null) return Container();

    double total = double.parse(uploadedItem!['price']) * 
                  double.parse(uploadedItem!['quantity']);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'فاتورة شراء',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'تاريخ الفاتورة: ${_formatDateTime(DateTime.now())}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'الصنف المشتراة:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${uploadedItem!['name']} - ${uploadedItem!['quantity']} ${uploadedItem!['unitName']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${uploadedItem!['price']} ريال ',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 2),
            Text(
              'الباركود: ${uploadedItem!['barcode'] ?? "غير متوفر"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الإجمالي:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$total ريال',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: closeInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF74826A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'إنهاء',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Unitdropbox extends StatelessWidget {
  const Unitdropbox({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final List<String> items;
  final String? value;
  final Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      initialValue: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يجب اختيار $label';
        }
        return null;
      },
    );
  }
}

class Accepteddropbox extends StatelessWidget {
  const Accepteddropbox({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final List<String> items;
  final String? value;
  final Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      initialValue: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يجب اختيار $label';
        }
        return null;
      },
    );
  }
}

class ScanBarcodeView extends StatefulWidget {
  final dynamic mainProduct;

  const ScanBarcodeView({Key? key, required this.mainProduct}) : super(key: key);

  @override
  State<ScanBarcodeView> createState() => _ScanBarcodeViewState();
}

class _ScanBarcodeViewState extends State<ScanBarcodeView> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isLoading = false;
  String? _scannedBarcode;
  bool _flashEnabled = false;
  bool _isGeneratingBarcode = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  String _generateRandomBarcode() {
    final random = Random();
    final barcode = List.generate(12, (index) => random.nextInt(10)).join();

    int sum = 0;
    for (int i = 0; i < barcode.length; i++) {
      final digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit * 1 : digit * 3;
    }
    final checkDigit = (10 - (sum % 10)) % 10;

    return barcode + checkDigit.toString();
  }

  Future<void> _generateAndSetBarcode() async {
    if (_isGeneratingBarcode) return;
    
    setState(() {
      _isGeneratingBarcode = true;
    });

    try {
      String generatedBarcode = _generateRandomBarcode();
      
      if (mounted) {
        setState(() {
          _scannedBarcode = generatedBarcode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم توليد باركود: $generatedBarcode'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingBarcode = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        centerTitle: true,
        backgroundColor: const Color(0xFF74826A),
        actions: [
          IconButton(
            icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                _flashEnabled = !_flashEnabled;
              });
              cameraController.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String barcode = barcodes.first.rawValue ?? '';
                if (barcode.isNotEmpty && _scannedBarcode != barcode) {
                  setState(() {
                    _scannedBarcode = barcode;
                  });
                  _processScannedBarcode(barcode);
                }
              }
            },
          ),
          CustomPaint(
            painter: BarcodeOverlay(
              borderColor: Colors.green,
              borderWidth: 4.0,
              overlayColor: Colors.black.withOpacity(0.5),
              cutOutSize: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Container(),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'generateBtn',
            backgroundColor: const Color(0xFF74826A),
            onPressed: _isGeneratingBarcode ? null : _generateAndSetBarcode,
            child: _isGeneratingBarcode
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Icon(Icons.qr_code, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'confirmBtn',
            backgroundColor: const Color(0xFF74826A),
            onPressed: () {
              if (_scannedBarcode == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لم يتم مسح أو توليد باركود بعد'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                Navigator.pop(context, _scannedBarcode);
              }
            },
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _processScannedBarcode(String barcode) async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context, barcode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في معالجة الباركود: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class BarcodeOverlay extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double cutOutSize;

  BarcodeOverlay({
    required this.borderColor,
    required this.borderWidth,
    required this.overlayColor,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final cutOutHalfSize = cutOutSize / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            centerX - cutOutHalfSize,
            centerY - cutOutHalfSize,
            centerX + cutOutHalfSize,
            centerY + cutOutHalfSize,
          ),
          Radius.circular(16),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          centerX - cutOutHalfSize,
          centerY - cutOutHalfSize,
          centerX + cutOutHalfSize,
          centerY + cutOutHalfSize,
        ),
        Radius.circular(16),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}