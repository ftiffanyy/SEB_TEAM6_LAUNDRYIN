import 'package:cloud_firestore/cloud_firestore.dart';

class StatusHistoryModel {
  final int statusHistoryId;
  final int orderId;
  final String notes;
  final int changedBy;
  final Timestamp changedAt;
  final String status;

  StatusHistoryModel({
    required this.statusHistoryId,
    required this.orderId,
    required this.notes,
    required this.changedBy,
    required this.changedAt,
    required this.status,
  });

  factory StatusHistoryModel.fromFirestore(Map<String, dynamic> data) {
    return StatusHistoryModel(
      statusHistoryId: data['status_history_id'],
      orderId: data['order_id'],
      notes: data['notes'],
      changedBy: data['changed_by'],
      changedAt: data['changed_at'],
      status: data['status'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'status_history_id': statusHistoryId,
      'order_id': orderId,
      'notes': notes,
      'changed_by': changedBy,
      'changed_at': changedAt,
      'status': status,
    };
  }
}