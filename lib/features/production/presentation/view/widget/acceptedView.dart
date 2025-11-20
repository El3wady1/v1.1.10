// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:inventory/core/utils/apiEndpoints.dart';
// import 'package:http/http.dart' as http;

// class AcceptedItem {
//   String id;
//   String productId;
//   String name;
//   String weight;
//   int quantity;
//   String status;
//   String date;

//   AcceptedItem({
//     required this.id,
//     required this.productId,
//     required this.name,
//     required this.weight,
//     required this.quantity,
//     required this.status,
//     required this.date,
//   });
// }

// class PendingRequestsPage extends StatefulWidget {
//   @override
//   _PendingRequestsPageState createState() => _PendingRequestsPageState();
// }

// class _PendingRequestsPageState extends State<PendingRequestsPage> {
//   // الألوان المحدثة
//   final Color primaryColor = Color(0xFF2E5E3A); // أخضر داكن
//   final Color accentColor = Color(0xFFE6B905); // أصفر ذهبي لامع
//   final Color secondaryColor = Color(0xFF8B9E7E); // أخضر باهت
//   final Color backgroundColor = Color(0xFFF8F8F8); // خلفية رمادية فاتحة
//   final Color textColor = Color(0xFF333333); // نص رمادي داكن
//   final Color lightTextColor = Color(0xFF666666); // نص رمادي فاتح

//   List<dynamic> pendingRequests = [];
//   bool isLoading = true;
//   String errorMessage = '';
//   Map<String, TextEditingController> quantityControllers = {};
//   bool isProcessingAll = false;

//   @override
//   void initState() {
//     super.initState();
//     fetchPendingRequests();
//   }

//   @override
//   void dispose() {
//     // تنظيف المتحكمات عند التخلص من الويدجت
//     quantityControllers.forEach((key, controller) => controller.dispose());
//     super.dispose();
//   }

//   Future<void> fetchPendingRequests() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//     });

//     try {
//       final response = await http.get(
//         Uri.parse("${Apiendpoints.baseUrl + Apiendpoints.production.getPending}"),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           pendingRequests = data['data'];
//           // تهيئة المتحكمات للكميات
//           for (var request in pendingRequests) {
//             String id = request['_id'];
//             quantityControllers[id] = TextEditingController(
//               text: request['qty']?.toString() ?? '0'
//             );
//           }
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//           errorMessage = 'فشل تحميل البيانات: ${response.statusCode}';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = 'خطأ: ${e.toString()}';
//       });
//     }
//   }

//   Future<void> approveRequest(String requestId) async {
//     try {
//       final response = await http.post(
//         Uri.parse('${Apiendpoints.baseUrl+Apiendpoints.production.approve}'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'requestIds': [requestId]
//         }),
//       );

//       if (response.statusCode == 200) {
//         fetchPendingRequests();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'تمت الموافقة على الطلب بنجاح',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: primaryColor,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//           ),
//         ));
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'فشل في الموافقة على الطلب: ${response.statusCode}',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.red[700],
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'خطأ: ${e.toString()}',
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.red[700],
//         ),
//       );
//     }
//   }

//   Future<void> refuseRequest(String requestId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('${Apiendpoints.baseUrl+Apiendpoints.production.refusePendingRequest}$requestId'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 200) {
//         fetchPendingRequests();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'تم رفض الطلب بنجاح',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: primaryColor,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'فشل في رفض الطلب: ${response.statusCode}',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.red[700],
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'خطأ: ${e.toString()}',
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.red[700],
//         ),
//       );
//     }
//   }

//   Future<void> updateQuantity(String requestId, String newQuantity) async {
//     try {
//       final response = await http.put(
//         Uri.parse('${Apiendpoints.baseUrl+Apiendpoints.production.updateQty}$requestId'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'qty': newQuantity
//         }),
//       );

//       if (response.statusCode == 200) {
//         fetchPendingRequests();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'تم تحديث الكمية بنجاح',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: primaryColor,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'فشل في تحديث الكمية: ${response.body}',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.red[700],
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'خطأ: ${e.toString()}',
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.red[700],
//         ),
//       );
//     }
//   }

//   Future<void> approveAllRequests() async {
//     if (pendingRequests.isEmpty) return;

//     setState(() {
//       isProcessingAll = true;
//     });

//     try {
//       List<String> requestIds = pendingRequests.map<String>((request) => request['_id']).toList();
      
//       final response = await http.post(
//         Uri.parse('${Apiendpoints.baseUrl+Apiendpoints.production.approve}'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'requestIds': requestIds
//         }),
//       );

//       if (response.statusCode == 200) {
//         fetchPendingRequests();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'تمت الموافقة على جميع الطلبات بنجاح',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: primaryColor,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'فشل في الموافقة على جميع الطلبات: ${response.statusCode}',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.red[700],
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'خطأ: ${e.toString()}',
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.red[700],
//         ),
//       );
//     } finally {
//       setState(() {
//         isProcessingAll = false;
//       });
//     }
//   }

//   Future<void> refuseAllRequests() async {
//     if (pendingRequests.isEmpty) return;

//     setState(() {
//       isProcessingAll = true;
//     });

//     try {
//       // في حالة عدم وجود نقطة نهاية لرفض الكل، نستخدم حلقة لرفض كل طلب على حدة
//       for (var request in pendingRequests) {
//         String requestId = request['_id'];
//         await http.delete(
//           Uri.parse('${Apiendpoints.baseUrl+Apiendpoints.production.refusePendingRequest}$requestId'),
//           headers: {'Content-Type': 'application/json'},
//         );
//       }

//       fetchPendingRequests();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'تم رفض جميع الطلبات بنجاح',
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: primaryColor,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'خطأ: ${e.toString()}',
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.red[700],
//         ),
//       );
//     } finally {
//       setState(() {
//         isProcessingAll = false;
//       });
//     }
//   }

//   String _formatDate(String dateString) {
//     try {
//       DateTime date = DateTime.parse(dateString);
//       return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//     } catch (e) {
//       return dateString;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         backgroundColor: backgroundColor,
      
//         body: isLoading
//             ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation<Color>(accentColor),
//                       strokeWidth: 5,
//                     ),
//                     SizedBox(height: 20),
//                     Text(
//                       'جاري تحميل البيانات...',
//                       style: TextStyle(
//                         color: textColor,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             : errorMessage.isNotEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.error_outline,
//                           size: 50,
//                           color: Colors.red[700],
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           errorMessage,
//                           style: TextStyle(
//                             color: Colors.red[700],
//                             fontSize: 18,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: fetchPendingRequests,
//                           child: Text('إعادة المحاولة'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: primaryColor,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 30, vertical: 12),
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 : Column(
//                     children: [
//                       if (pendingRequests.isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             children: [
//                               ElevatedButton.icon(
//                                 icon: isProcessingAll 
//                                     ? CircularProgressIndicator(
//                                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                         strokeWidth: 2,
//                                       )
//                                     : Icon(Icons.check_circle_outline),
//                                 label: Text('قبول الكل',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600),),
//                                 onPressed: isProcessingAll ? null : approveAllRequests,
//                                 style: ElevatedButton.styleFrom(
//                                   foregroundColor: Colors.white,
//                                   backgroundColor: primaryColor,
//                                   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                               ),
//                               ElevatedButton.icon(
//                                 icon: isProcessingAll 
//                                     ? CircularProgressIndicator(
//                                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                         strokeWidth: 2,
//                                       )
//                                     : Icon(Icons.highlight_off),
//                                 label: Text('رفض الكل',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600),),
//                                 onPressed: isProcessingAll ? null : refuseAllRequests,
//                                 style: ElevatedButton.styleFrom(
//                                   foregroundColor: Colors.white,
//                                   backgroundColor: Colors.red[700],
//                                   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       Expanded(
//                         child: pendingRequests.isEmpty
//                             ? Center(
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.inventory_2_outlined,
//                                       size: 70,
//                                       color: secondaryColor,
//                                     ),
//                                     SizedBox(height: 20),
//                                     Text(
//                                       'لا توجد طلبات معلقة حالياً',
//                                       style: TextStyle(
//                                         fontSize: 20,
//                                         color: textColor,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     SizedBox(height: 10),
//                                     Text(
//                                       'سيظهر هنا أي طلبات جديدة تحتاج إلى موافقتك',
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         color: lightTextColor,
//                                       ),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   ],
//                                 ),
//                               )
//                             : SingleChildScrollView(
//                                 scrollDirection: Axis.horizontal,
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(16.0),
//                                   child: DataTable(
//                                     columnSpacing: 20,
//                                     horizontalMargin: 10,
//                                     headingRowColor: MaterialStateColor.resolveWith(
//                                         (states) => primaryColor.withOpacity(0.1)),
//                                     headingTextStyle: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       color: primaryColor,
//                                       fontSize: 16,
//                                     ),
//                                     dataRowColor: MaterialStateColor.resolveWith(
//                                         (states) => Colors.white),
//                                     columns: [
//                                       DataColumn(label: Text('رقم الطلب')),
//                                       DataColumn(label: Text('اسم المنتج')),
//                                       DataColumn(
//                                         label: Text('الكمية'),
//                                         numeric: true,
//                                       ),
//                                       DataColumn(label: Text('تاريخ الإنشاء')),
//                                       DataColumn(label: Text('الإجراءات')),
//                                     ],
//                                     rows: pendingRequests.map((request) {
//                                       String requestId = request['_id'];
//                                       return DataRow(cells: [
//                                         DataCell(Text(
//                                           '#${pendingRequests.indexOf(request) + 1}',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         )),
//                                         DataCell(
//                                           Text(request['product']['name'] ?? 'غير محدد'),
//                                         ),
//                                         DataCell(
//                                           Row(
//                                             children: [
//                                               SizedBox(
//                                                 width: 60,
//                                                 child: TextField(
//                                                   controller: quantityControllers[requestId],
//                                                   keyboardType: TextInputType.number,
//                                                   decoration: InputDecoration(
//                                                     border: OutlineInputBorder(),
//                                                     contentPadding: EdgeInsets.symmetric(
//                                                         horizontal: 8, vertical: 4),
//                                                   ),
//                                                 ),
//                                               ),
//                                               IconButton(
//                                                 icon: Icon(Icons.check,
//                                                     color: primaryColor),
//                                                 onPressed: () {
//                                                   updateQuantity(
//                                                     requestId,
//                                                     quantityControllers[requestId]!.text,
//                                                   );
//                                                 },
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         DataCell(
//                                           Text(request['createdAt'] != null
//                                               ? _formatDate(request['createdAt'])
//                                               : 'غير محدد'),
//                                         ),
//                                         DataCell(
//                                           Row(
//                                             children: [
//                                               ElevatedButton(
//                                                 onPressed: () =>
//                                                     approveRequest(requestId),
//                                                 child: Text('موافقة'),
//                                                 style: ElevatedButton.styleFrom(
//                                                   foregroundColor: Colors.white,
//                                                   backgroundColor: primaryColor,
//                                                   padding: EdgeInsets.symmetric(
//                                                       horizontal: 12, vertical: 8),
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(6),
//                                                   ),
//                                                 ),
//                                               ),
//                                               SizedBox(width: 8),
//                                               OutlinedButton(
//                                                 onPressed: () =>
//                                                     refuseRequest(requestId),
//                                                 child: Text('رفض',
//                                                     style: TextStyle(
//                                                         color: Colors.red[700])),
//                                                 style: OutlinedButton.styleFrom(
//                                                   side: BorderSide(
//                                                       color: Colors.red[700]!),
//                                                   padding: EdgeInsets.symmetric(
//                                                       horizontal: 12, vertical: 8),
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(6),
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ]);
//                                     }).toList(),
//                                   ),
//                                 ),
//                               ),
//                       ),
//                     ],
//                   ),
//       ),
//     );
//   }
// }