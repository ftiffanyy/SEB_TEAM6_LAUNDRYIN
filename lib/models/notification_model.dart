import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final int notificationId;
  final int orderId;
  final int userId;
  final String title;
  final String message;
  final Timestamp sentAt;
  final bool isRead;
  final String type;

  NotificationModel({
    required this.notificationId,
    required this.orderId,
    required this.userId,
    required this.title,
    required this.message,
    required this.sentAt,
    required this.isRead,
    required this.type,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data) {
    return NotificationModel(
      notificationId: data['notification_id'],
      orderId: data['order_id'],
      userId: data['user_id'],
      title: data['title'],
      message: data['message'],
      sentAt: data['sent_at'],
      isRead: data['is_read'],
      type: data['type'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'notification_id': notificationId,
      'order_id': orderId,
      'user_id': userId,
      'title': title,
      'message': message,
      'sent_at': sentAt,
      'is_read': isRead,
      'type': type,
    };
  }
}