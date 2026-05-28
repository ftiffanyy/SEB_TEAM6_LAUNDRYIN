import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/laundry_order_model.dart';
import '../models/order_detail_model.dart';
import '../services/firestore_service.dart';

class CreateOrderViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> createOrder({
    required int customerId,
    required int cashierId,
    required int serviceId,
    required int weight,
    required int totalAmount,
    required String notes,
  }) async {
    final orderId = DateTime.now().millisecondsSinceEpoch;
    final orderCode = 'ORD-$orderId';

    final order = LaundryOrderModel(
      orderId: orderId,
      orderCode: orderCode,
      userId: customerId,
      createdBy: cashierId,
      orderDate: Timestamp.now(),
      totalWeight: weight,
      totalAmount: totalAmount,
      notes: notes,
      status: 'Received',
    );

    final orderDetail = OrderDetailModel(
      orderDetailId: orderId,
      orderId: orderId,
      serviceId: serviceId,
      weight: weight,
    );

    await _firestoreService.addOrder(order);
    await _firestoreService.addOrderDetail(orderDetail);
  }
}