import 'package:flutter/material.dart';

// نموذج إشعار المخزون
class NotificationItem {
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  NotificationItem({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });
}

class Notificationsbodyview extends StatelessWidget {
  const Notificationsbodyview({super.key});

  // إشعارات محاكاة لمخزون
  Future<List<NotificationItem>> fetchNotifications() async {
    await Future.delayed(const Duration(seconds: 2)); // محاكاة تحميل
    return [
      NotificationItem(
        title: 'الكمية منخفضة',
        body: 'منتج "مياه معدنية" اقترب من النفاد (5 وحدات متبقية).',
        icon: Icons.warning_amber_rounded,
        color: Colors.orange,
      ),
      NotificationItem(
        title: 'إعادة الطلب',
        body: 'منتج "معجون أسنان" يحتاج لإعادة الطلب.',
        icon: Icons.replay_circle_filled_rounded,
        color: Colors.blue,
      ),
      NotificationItem(
        title: 'انتهاء الصلاحية',
        body: 'منتج "لبن طويل الأجل" سينتهي خلال 3 أيام.',
        icon: Icons.event_busy_rounded,
        color: Colors.redAccent,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationItem>>(
      future: fetchNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد إشعارات حالياً.'));
        }

        final notifications = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final n = notifications[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: n.color.withOpacity(0.1),
                  child: Icon(n.icon, color: n.color, size: 26),
                ),
                title: Text(
                  n.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  n.body,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}
