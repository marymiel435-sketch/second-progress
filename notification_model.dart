import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? type;
  final String? orderId;

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type,
    this.orderId,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    // This helper ensures we never crash on null or weird timestamps
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      // Handle the case where it might be a String or null (common with serverTimestamp())
      return DateTime.now(); 
    }

    return NotificationModel(
      id: documentId,
      userId: data['userId']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Notification',
      body: data['body']?.toString() ?? '',
      createdAt: parseDateTime(data['createdAt']),
      isRead: data['isRead'] == true,
      type: data['type']?.toString(),
      orderId: data['orderId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'createdAt': createdAt,
      'isRead': isRead,
      'type': type,
      'orderId': orderId,
    };
  }
}
