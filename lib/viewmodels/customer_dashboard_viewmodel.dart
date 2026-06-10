import '../models/laundry_order_model.dart';
import '../models/order_detail_model.dart';
import '../services/firestore_service.dart';
import '../models/service_model.dart';

class CustomerOrderItem {
  final LaundryOrderModel order;
  final String serviceName;
  final int estimatedDays;
  final int servicePrice;

  CustomerOrderItem({
    required this.order,
    required this.serviceName,
    required this.estimatedDays,
    required this.servicePrice,
  });
}

class CustomerDashboardViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<CustomerOrderItem>> getCustomerOrderItems(int userId) async {
    final orders = await _firestoreService.getOrders();
    final services = await _firestoreService.getServices();
    final orderDetails = await _firestoreService.getOrderDetails();

    final userOrders = orders
        .where((o) => o.userId == userId)
        .toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

    final List<CustomerOrderItem> items = [];

    for (final order in userOrders) {
      final detail = orderDetails.firstWhere(
        (d) => d.orderId == order.orderId,
        orElse: () => OrderDetailModel(
          orderDetailId: 0,
          orderId: order.orderId,
          serviceId: 0,
          weight: 0,
        ),
      );

      final service = services.firstWhere(
        (s) => s.serviceId == detail.serviceId,
        orElse: () => ServiceModel(
          serviceId: 0,
          serviceName: 'Unknown Service',
          estimatedDays: 0,
          servicePrice: 0,
          description: 'No description',
          isActive: false,
        ),
      );

      items.add(CustomerOrderItem(
        order: order,
        serviceName: service.serviceName,
        estimatedDays: service.estimatedDays,
        servicePrice: service.servicePrice,
      ));
    }

    return items;
  }

  List<CustomerOrderItem> getActiveOrders(List<CustomerOrderItem> items) {
    return items.where((item) {
      final s = item.order.status.toLowerCase();
      return s != 'picked up';
    }).toList();
  }

  List<CustomerOrderItem> getCompletedOrders(List<CustomerOrderItem> items) {
    return items.where((item) {
      return item.order.status.toLowerCase() == 'picked up';
    }).toList();
  }
}