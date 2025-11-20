import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class OfflineOutTransactionsScreen extends StatefulWidget {
  @override
  _OfflineOutTransactionsScreenState createState() =>
      _OfflineOutTransactionsScreenState();
}

class _OfflineOutTransactionsScreenState
    extends State<OfflineOutTransactionsScreen> {
  List<Map<String, dynamic>> offlineData = [];

  @override
  void initState() {
    super.initState();
    loadOfflineData();
  }

  Future<void> loadOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> offlineStrings =
        prefs.getStringList('offline_out_transactionsss') ?? [];

    setState(() {
      offlineData =
          offlineStrings.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> deleteItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> offlineStrings =
        prefs.getStringList('offline_out_transactionsss') ?? [];

    if (index >= 0 && index < offlineStrings.length) {
      offlineStrings.removeAt(index);
      await prefs.setStringList('offline_out_transactionsss', offlineStrings);
      setState(() {
        offlineData.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            '📦 عمليات الاخراج غير المتصلة',
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: offlineData.isEmpty
            ? Center(
                child: Text(
                  'لا توجد بيانات حالياً',
                  style: GoogleFonts.cairo(color: Colors.black54, fontSize: 18),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: offlineData.length,
                itemBuilder: (context, index) {
                  final item = offlineData[index];
                  return GlassCard(
                    item: item,
                    onDelete: () => deleteItem(index),
                  );
                },
              ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const GlassCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoRow(title: "🧑‍💼 المستخدم", value: item['userID']),
            InfoRow(title: "🏷️ المنتج", value: item['productID']),
            InfoRow(title: "🏢 القسم", value: item['department']),
            InfoRow(title: "📦 الكمية", value: item['quantity'].toString()),
            InfoRow(title: "📏 الوحدة", value: item['unit']),
            InfoRow(title: "🚚 المورد", value: item['supplier']),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: Icon(Icons.delete_forever, color: Colors.redAccent),
                label: Text(
                  'حذف',
                  style: GoogleFonts.cairo(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          text: '$title: ',
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
