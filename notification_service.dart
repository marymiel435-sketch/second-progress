import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // CREATE NOTIFICATION
  Future<void> createNotification(NotificationModel notification) async {
    try {
      if (notification.userId.isEmpty) {
        print("[NOTIF_LOG] ERROR: userId is empty, cannot create notification.");
        return;
      }

      await _db.collection('notifications').add({
        'userId': notification.userId,
        'title': notification.title,
        'body': notification.body,
        'isRead': false,
        'type': notification.type,
        'orderId': notification.orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print("[NOTIF_LOG] SUCCESS: Notification saved for user ${notification.userId}");
    } catch (e) {
      print("[NOTIF_LOG] CRITICAL ERROR: $e");
    }
  }

  // GET ALL NOTIFICATIONS (Real-time Stream)
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
          
          // Sort newest first in Dart
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  // STREAM FOR THE LATEST UNREAD NOTIFICATION (To trigger SnackBars)
  Stream<NotificationModel?> getLatestUnreadNotification(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
          
          // Sort by date to get the absolute newest one
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications.first;
        });
  }

  // MARK AS READ
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (e) {
      print("[NOTIF_LOG] ERROR marking read: $e");
    }
  }

  // MARK ALL AS READ
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _db.batch();
      final query = await _db.collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print("[NOTIF_LOG] ERROR marking all read: $e");
    }
  }
}
