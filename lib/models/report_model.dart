import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final int reportId;
  final Timestamp startDate;
  final Timestamp endDate;
  final int totalOrders;
  final int totalRevenue;
  final Timestamp generatedAt;

  ReportModel({
    required this.reportId,
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.totalRevenue,
    required this.generatedAt,
  });

  factory ReportModel.fromFirestore(Map<String, dynamic> data) {
    return ReportModel(
      reportId: data['report_id'],
      startDate: data['start_date'],
      endDate: data['end_date'],
      totalOrders: data['total_orders'],
      totalRevenue: data['total_revenue'],
      generatedAt: data['generated_at'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'report_id': reportId,
      'start_date': startDate,
      'end_date': endDate,
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'generated_at': generatedAt,
    };
  }
}