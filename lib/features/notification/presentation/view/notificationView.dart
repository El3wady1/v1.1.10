import 'package:flutter/material.dart';
import 'package:saladafactory/features/login/presentation/view/loginView.dart';
import 'package:saladafactory/features/notification/presentation/view/widgets/notificationsBodyView.dart';

class Notificationview extends StatelessWidget {
  const Notificationview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
           appBar: AppBar(
          title: const Text('الاشعارات'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Loginview()),
                );
              },
            ),
          ],
        ),
    
      body: Notificationsbodyview());
  }
}