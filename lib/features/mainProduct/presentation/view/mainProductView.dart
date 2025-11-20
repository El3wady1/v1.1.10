import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:saladafactory/core/app_router.dart';
import 'dart:convert';

import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/features/scanBarCode/presentation/view/scanbarCodeView.dart';

import '../../../home/data/repo/ReturnLastloginRepo.dart';
import '../../../in/data/services/getAllSupplierINServices.dart';
import '../../../in/data/services/getAllunitService.dart';
import '../../../in/data/services/getProductByBarcodeINService.dart';
import '../../../in/presentation/view/inView.dart';

class MainCategorySelectionPage extends StatefulWidget {
  var barcode;
bool isexitsProduct;
  MainCategorySelectionPage({required this.barcode,required this.isexitsProduct});
  @override
  _MainCategorySelectionPageState createState() =>
      _MainCategorySelectionPageState();
}

class _MainCategorySelectionPageState extends State<MainCategorySelectionPage> {
  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _showAddNewCategory = false;
  final TextEditingController _newCategoryController = TextEditingController();

  // Color palette
  final Color primaryColor = const Color(0xFF74826A);
  final Color accentColor = const Color(0xFFEDBE2C);
  final Color secondaryColor = const Color(0xFFCDBCA2);
  final Color backgroundColor = const Color(0xFFF3F4EF);

  @override
  void initState() {
    super.initState();
    _fetchMainCategories();
   if (widget.isexitsProduct==true){
    isProductExistHandel();
   }
  }
isProductExistHandel()async{
     var productdata;
    var supplierData;
    var unitData;

    await getAllUnitINServices().then((v) => unitData = v);
    await getAllSupplierINServices().then((v) => supplierData = v);
    await getProductByBarcodeINService(barbracode:widget.barcode, context: context)
        .then((v) => productdata = v);
         var data = await ReturnLastloginRepo.featchData();

      Routting.pushreplaced(
      context,
      Inview(
        initialBarcode:widget.barcode,
        isExist: productdata != null ? true : false,
        SupplierData: supplierData,
        unitData: unitData,
        mainProduct: _selectedCategoryId, canAddPernew:data["canaddProductIN"] ,
      ),);
}
  Future<void> _fetchMainCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          '${Apiendpoints.baseUrl + Apiendpoints.mainProduct.getAll}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _categories = data['data'];
          _isLoading = false;
        });
      } else {
        throw Exception('فشل في تحميل الأصناف');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}')),
      );
    }
  }

  Future<void> _addNewCategory() async {
    if (_newCategoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخل اسم الصنف')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Apiendpoints.baseUrl + Apiendpoints.mainProduct.add}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _newCategoryController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _newCategoryController.clear();
        await _fetchMainCategories();
        setState(() {
          _showAddNewCategory = false;
          _selectedCategoryId = responseData['data']['_id'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الصنف بنجاح')),
        );
      } else {
        throw Exception('فشل في إضافة الصنف');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}')),
      );
    }
  }

  void _proceedToNext() async{
    if (_selectedCategoryId == null && !_showAddNewCategory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('من فضلك اختر صنفًا رئيسيًا أو أضف صنفًا جديدًا')),
      );
      return;
    }

    if (_showAddNewCategory) {
      _addNewCategory();
    } else {
       var productdata;
    var supplierData;
    var unitData;

    await getAllUnitINServices().then((v) => unitData = v);
    await getAllSupplierINServices().then((v) => supplierData = v);
    await getProductByBarcodeINService(barbracode:widget.barcode, context: context)
        .then((v) => productdata = v);
         var data = await ReturnLastloginRepo.featchData();

      Routting.pushreplaced(
      context,
      Inview(
        initialBarcode:widget.barcode,
        isExist: productdata != null ? true : false,
        SupplierData: supplierData,
        unitData: unitData,
        mainProduct: _selectedCategoryId, canAddPernew:data["canaddProductIN"] ,
      ),);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
      
        backgroundColor: backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading:  widget.isexitsProduct==true?false:true,
          title: Text(
           widget.isexitsProduct==true?"انتظر...": 'اختيار الصنف الرئيسي',
            style: GoogleFonts.cairo(color: accentColor),
          ),
          backgroundColor: primaryColor,
          centerTitle: true,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              )
            :  widget.isexitsProduct==true?Center(child: CircularProgressIndicator(),):Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_showAddNewCategory) ...[
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategoryId,
                            hint: Text(
                              'اختر صنفًا رئيسيًا',
                              style: GoogleFonts.cairo(),    textAlign: TextAlign.right, // محاذاة النص لليمين

                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category['_id'],
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      category['name'],
                                          textAlign: TextAlign.right, // محاذاة النص لليمين
                                    
                                      style: GoogleFonts.cairo(color: primaryColor),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            },
                            decoration:  InputDecoration(
                              border: InputBorder.none,
                              labelText: 'الأصناف الرئيسية',
                              labelStyle: GoogleFonts.cairo()
                            ),
                            icon: Icon(Icons.arrow_drop_down,
                                color: primaryColor),
                            dropdownColor: backgroundColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAddNewCategory = true;
                            _selectedCategoryId = null;
                          });
                        },
                        child: Text(
                          'لم أجد الصنف المطلوب، أريد إضافة صنف جديد',
                          style: GoogleFonts.cairo(color: accentColor),
                        ),
                      ),
                    ] else ...[
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إضافة صنف رئيسي جديد',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _newCategoryController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: secondaryColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  labelText: 'اسم الصنف',
                                  labelStyle:
                                      GoogleFonts.cairo(color: primaryColor),
                                  hintText: "اكتب اسم صنف الرئيسي الجديد...",
                                  hintStyle: GoogleFonts.cairo()
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _showAddNewCategory = false;
                                        _newCategoryController.clear();
                                      });
                                    },
                                    child: Text('رجوع',
                                        style: GoogleFonts.cairo()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: secondaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: _addNewCategory,
                                    child: Text(
                                      'إضافة',
                                      style: GoogleFonts.cairo(),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _proceedToNext,
                      child: Text(
                        'التالي',
                        style: GoogleFonts.cairo(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }
}
