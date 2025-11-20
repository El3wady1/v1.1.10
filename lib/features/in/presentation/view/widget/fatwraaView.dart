import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:saladafactory/core/app_router.dart';
import 'package:saladafactory/core/utils/Strings.dart';
import 'package:saladafactory/core/utils/apiEndpoints.dart';
import 'package:saladafactory/features/home/presentation/view/widget/succesView.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddFatwraScreen extends StatefulWidget {
  const AddFatwraScreen({Key? key}) : super(key: key);

  @override
  _AddFatwraScreenState createState() => _AddFatwraScreenState();
}

class _AddFatwraScreenState extends State<AddFatwraScreen> {
  // ألوان التطبيق
  final Color _primaryColor = const Color(0xFF74826A);
  final Color _accentColor = const Color(0xFFEDBE2C);
  final Color _backgroundColor = const Color(0xFFF3F4EF);

  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  bool _isLoading = false;

  Future<void> _captureImage(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء فتح الكاميرا: ${e.toString()}',context);
    }
  }

  Future<void> _submitFatwra(BuildContext context) async {
    if (_notesController.text.isEmpty || _capturedImage == null) {
      _showErrorSnackBar('الرجاء إدخال الملاحظات وتصوير الفاتورة',context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Strings.tokenKey);

      if (token == null) {
        _showErrorSnackBar('يجب تسجيل الدخول أولاً',context);
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(Apiendpoints.baseUrl+Apiendpoints.fatwra.add),
      );

      request.headers['authorization'] = 'Bearer $token';
      request.fields['name'] = _notesController.text;

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _capturedImage!.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final response = await request.send();

      if (response.statusCode == 200) {
        _showSuccessSnackBar('تم حفظ الفاتورة بنجاح',context);
        _resetForm();
      } else {
        _showSuccessSnackBar('تم حفظ الفاتورة بنجاح',context);
Navigator.pop(context);  Navigator.pop(context);  
Routting.push(context,SuccessPage());    }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ: ${e.toString()}',context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _notesController.clear();
    setState(() => _capturedImage = null);
  }

  void _showSuccessSnackBar(String message,BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message ,BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: const Text('إضافة فاتورة جديدة'),
          backgroundColor: _primaryColor,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // حقل الملاحظات
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'ملاحظات على الفاتورة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 25),

              // زر التقاط الصورة
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('تصوير الفاتورة'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, backgroundColor: _accentColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:()=> _captureImage(context),
              ),

              const SizedBox(height: 20),

              // معاينة الصورة
              if (_capturedImage != null) ...[
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _capturedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'تم تصوير الفاتورة',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
              ],

              // زر الحفظ
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed:()=> _submitFatwra(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: _primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('حفظ الفاتورة'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}