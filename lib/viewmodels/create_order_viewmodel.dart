import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/service_model.dart';
import '../models/laundry_order_model.dart';
import '../models/order_detail_model.dart';
import '../services/firestore_service.dart';

class CreateOrderViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<UserModel>> getCustomers() async {
    final users = await _firestoreService.getUsers();
    return users.where((user) => user.role == 'Customer').toList();
  }

  Future<List<ServiceModel>> getServices() async {
    return await _firestoreService.getServices();
  }

  Future<UserModel> addNewCustomer({
    required String name,
    required String phone,
  }) async {
    final newId = DateTime.now().millisecondsSinceEpoch;

    final customer = UserModel(
      userId: newId,
      name: name,
      username: null,
      password: null,
      phone: phone,
      address: null,
      fcmToken: null,
      role: 'Customer',
    );

    await _firestoreService.addUser(customer);
    return customer;
  }

  Future<void> createOrder({
    required UserModel customer,
    required int cashierId,
    required ServiceModel service,
    required int weight,
    required int totalAmount,
    required String notes,
  }) async {
    final orderId = DateTime.now().millisecondsSinceEpoch;
    final orderCode = 'ORD$orderId';

    final order = LaundryOrderModel(
      orderId: orderId,
      orderCode: orderCode,
      userId: customer.userId,
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
      serviceId: service.serviceId,
      weight: weight,
    );

    await _firestoreService.addOrder(order);
    await _firestoreService.addOrderDetail(orderDetail);
  }
}