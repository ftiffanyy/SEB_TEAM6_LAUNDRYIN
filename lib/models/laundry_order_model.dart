import 'package:cloud_firestore/cloud_firestore.dart';

class LaundryOrderModel {
  final int orderId;
  final String orderCode;
  final int userId;
  final int createdBy;
  final Timestamp orderDate;
  final int totalWeight;
  final int totalAmount;
  final String notes;
  final String status;

  LaundryOrderModel({
    required this.orderId,
    required this.orderCode,
    required this.userId,
    required this.createdBy,
    required this.orderDate,
    required this.totalWeight,
    required this.totalAmount,
    required this.notes,
    required this.status,
  });

  factory LaundryOrderModel.fromFirestore(Map<String, dynamic> data) {
    return LaundryOrderModel(
      orderId: data['order_id'] ?? 0,
      orderCode: data['order_code'] ?? '',
      userId: data['user_id'] ?? 0,
      createdBy: data['created_by'] ?? 0,
      orderDate: data['order_date'] ?? Timestamp.now(),
      totalWeight: data['total_weight'] ?? 0,
      totalAmount: data['total_amount'] ?? 0,
      notes: data['notes'] ?? '',
      status: data['status'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'order_id': orderId,
      'order_code': orderCode,
      'user_id': userId,
      'created_by': createdBy,
      'order_date': orderDate,
      'total_weight': totalWeight,
      'total_amount': totalAmount,
      'notes': notes,
      'status': status,
    };
  }
}