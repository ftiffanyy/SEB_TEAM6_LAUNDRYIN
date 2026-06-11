import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

import '../models/laundry_order_model.dart';
import '../services/firestore_service.dart';

class EmployeeDashboardViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  String normalizeStatus(String status) {
    return status.toLowerCase().trim();
  }

  bool isCompletedOrder(String status) {
    return normalizeStatus(status) == 'picked up';
  }

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final List<LaundryOrderModel> orders = await _firestoreService.getOrders();

    int totalOrders = orders.length;
    int totalRevenue = 0;
    int completedOrders = 0;
    int activeOrders = 0;

    for (var order in orders) {
      totalRevenue += order.totalAmount;

      if (isCompletedOrder(order.status)) {
        completedOrders++;
      } else {
        activeOrders++;
      }
    }

    return {
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'completedOrders': completedOrders,
      'activeOrders': activeOrders,
      'orders': orders,
    };
  }

  Future<Map<String, dynamic>> getFilteredReport(
    DateTime from,
    DateTime to,
  ) async {
    final List<LaundryOrderModel> orders = await _firestoreService.getOrders();

    final filtered = orders.where((order) {
      final dt = order.orderDate.toDate();
      return !dt.isBefore(from) && !dt.isAfter(to);
    }).toList();

    int totalOrders = filtered.length;
    int totalRevenue = 0;
    int completedOrders = 0;
    int activeOrders = 0;

    for (var order in filtered) {
      totalRevenue += order.totalAmount;

      if (isCompletedOrder(order.status)) {
        completedOrders++;
      } else {
        activeOrders++;
      }
    }

    return {
      'from': from,
      'to': to,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'completedOrders': completedOrders,
      'activeOrders': activeOrders,
      'orders': filtered,
    };
  }

  String generateCsv(List<LaundryOrderModel> orders) {
    final buffer = StringBuffer();

    buffer.writeln(
      'order_id,order_code,order_date,total_weight,total_amount,status',
    );

    for (var o in orders) {
      final date = o.orderDate.toDate().toIso8601String();

      buffer.writeln(
        '${o.orderId},${o.orderCode},$date,${o.totalWeight},${o.totalAmount},${o.status}',
      );
    }

    return buffer.toString();
  }

  Future<Uint8List> generatePdfBytes(List<LaundryOrderModel> orders) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');

    final headers = [
      'Order ID',
      'Code',
      'Date',
      'Weight',
      'Amount',
      'Status',
    ];

    final data = orders.map((o) {
      return [
        o.orderId.toString(),
        o.orderCode,
        dateFormat.format(o.orderDate.toDate()),
        o.totalWeight.toString(),
        o.totalAmount.toString(),
        o.status,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Laporan Pesanan'),
          ),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateExcelBytes(List<LaundryOrderModel> orders) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];

    sheet.appendRow([
      'order_id',
      'order_code',
      'order_date',
      'total_weight',
      'total_amount',
      'status',
    ]);

    for (var o in orders) {
      sheet.appendRow([
        o.orderId,
        o.orderCode,
        o.orderDate.toDate().toIso8601String(),
        o.totalWeight,
        o.totalAmount,
        o.status,
      ]);
    }

    final bytes = excel.encode();

    return Uint8List.fromList(bytes ?? <int>[]);
  }
}