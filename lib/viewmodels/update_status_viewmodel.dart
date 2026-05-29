import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/laundry_order_model.dart';
import '../models/status_history_model.dart';
import '../services/firestore_service.dart';

class OrderStatusItem {
  final LaundryOrderModel order;
  final String customerName;
  final String serviceName;

  OrderStatusItem({
    required this.order,
    required this.customerName,
    required this.serviceName,
  });
}

class UpdateStatusViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<OrderStatusItem>> getOrderStatusItems() async {
    final orders = await _firestoreService.getOrders();
    final users = await _firestoreService.getUsers();
    final services = await _firestoreService.getServices();
    final orderDetails = await _firestoreService.getOrderDetails();

    final activeOrders = orders.where((order) {
      return order.status.toLowerCase() != 'completed' &&
          order.status.toLowerCase() != 'picked up';
    }).toList();

    final List<OrderStatusItem> items = [];

    for (final order in activeOrders) {
      final customer = users.where((user) {
        return user.userId == order.userId;
      }).toList();

      final detail = orderDetails.where((detail) {
        return detail.orderId == order.orderId;
      }).toList();

      if (customer.isEmpty || detail.isEmpty) {
        continue;
      }

      final service = services.where((service) {
        return service.serviceId == detail.first.serviceId;
      }).toList();

      if (service.isEmpty) {
        continue;
      }

      items.add(
        OrderStatusItem(
          order: order,
          customerName: customer.first.name,
          serviceName: service.first.serviceName,
        ),
      );
    }

    return items;
  }

  Future<int> getNextStatusHistoryId() async {
    final histories = await _firestoreService.getStatusHistories();

    if (histories.isEmpty) {
      return 1;
    }

    final maxId = histories
        .map((history) => history.statusHistoryId)
        .reduce((a, b) => a > b ? a : b);

    return maxId + 1;
  }

  Future<void> updateStatus({
    required LaundryOrderModel order,
    required String newStatus,
    required int changedBy,
    required String notes,
  }) async {
    await _firestoreService.updateOrderStatus(
      order.orderId,
      newStatus,
    );

    final statusHistoryId = await getNextStatusHistoryId();

    final history = StatusHistoryModel(
      statusHistoryId: statusHistoryId,
      orderId: order.orderId,
      notes: notes,
      changedBy: changedBy,
      changedAt: Timestamp.now(),
      status: newStatus,
    );

    await _firestoreService.addStatusHistory(history);
  }
}