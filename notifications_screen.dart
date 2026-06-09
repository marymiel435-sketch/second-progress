import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService notificationService = NotificationService();
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF03A9F4),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orangeAccent),
            onPressed: () {
              notificationService.createNotification(NotificationModel(
                userId: user.uid,
                title: "System Test",
                body: "This is a test to verify notifications are working.",
                createdAt: DateTime.now(),
                type: 'accepted',
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => notificationService.markAllAsRead(user.uid),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: notificationService.getUserNotifications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final notifications = snapshot.data ?? [];
                
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none, size: 60, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text("No notifications yet", style: TextStyle(color: Colors.grey)),
                        Text("ID: ${user.uid.substring(0, 8)}...", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return Card(
                      color: n.isRead ? Colors.white : const Color(0xFFE3F2FD),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(_getIcon(n.type))),
                        title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                        subtitle: Text(n.body),
                        trailing: Text(DateFormat('h:mm a').format(n.createdAt), style: const TextStyle(fontSize: 10)),
                        onTap: () => notificationService.markAsRead(n.id!),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String? type) {
    if (type == 'accepted') return Icons.check_circle;
    if (type == 'on the way') return Icons.moped;
    if (type == 'delivered') return Icons.card_giftcard;
    if (type == 'price_updated') return Icons.payments;
    return Icons.notifications;
  }
}
