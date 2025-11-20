import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saladafactory/features/profile/data/repo/getUserProfileRepo.dart';
import 'package:saladafactory/features/profile/presentation/widget/profileBodyView.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profileview extends StatefulWidget {
  const Profileview({super.key});

  @override
  State<Profileview> createState() => _ProfileviewState();
}

class _ProfileviewState extends State<Profileview> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserProfile();
  }

  Future<Map<String, dynamic>> _loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      /// جلب البيانات من API
      final data = await Getuserprofilerepo.featchData();

      /// تخزينها في SharedPreferences
      await prefs.setString('cachedUserProfile', jsonEncode(data));

      return data;
    } catch (e) {
      /// في حالة الخطأ، نحاول قراءة البيانات من SharedPreferences
      final cachedData = prefs.getString('cachedUserProfile');
      if (cachedData != null) {
        return jsonDecode(cachedData);
      } else {
        /// لا يوجد بيانات مخزنة
        throw Exception('لا يوجد اتصال ولا بيانات مخزنة');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off,
                      size: MediaQuery.of(context).size.width * .3,
                      color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "تعذر تحميل البيانات.\nيرجى التحقق من الاتصال أو المحاولة لاحقاً.",
                    style: GoogleFonts.cairo(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _userDataFuture = _loadUserProfile();
                      });
                    },
                    child: const Text("إعادة المحاولة"),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(
              child: Text('لا توجد بيانات للمستخدم'),
            ),
          );
        }

        /// ✅ تمرير البيانات إلى bodyView
        return Profilebodyview(userData: snapshot.data!);
      },
    );
  }
}
