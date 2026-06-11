import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/service_model.dart';
import '../models/laundry_order_model.dart';
import '../models/order_detail_model.dart';
import '../services/firestore_service.dart';
import '../utils/phone_helper.dart';

class CreateOrderViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  final List<String> allowedPaymentMethods = [
    'Debit Card',
    'Credit Card',
    'QRIS',
  ];

  Future<List<UserModel>> getCustomers() async {
    final users = await _firestoreService.getUsers();
    return users.where((user) => user.role == 'Customer').toList();
  }

  Future<List<ServiceModel>> getServices() async {
    final services = await _firestoreService.getServices();
    return services.where((service) => service.isActive).toList();
  }

  Future<int> getNextOrderId() async {
    final orders = await _firestoreService.getOrders();

    if (orders.isEmpty) return 1;

    final maxOrderId = orders
        .map((order) => order.orderId)
        .reduce((a, b) => a > b ? a : b);

    return maxOrderId + 1;
  }

  Future<String> getNextOrderCode() async {
    final orderId = await getNextOrderId();
    return 'ORD${orderId.toString().padLeft(3, '0')}';
  }

  Future<int> getNextUserId() async {
    final users = await _firestoreService.getUsers();

    if (users.isEmpty) return 1;

    return users.map((e) => e.userId).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<UserModel> findOrCreateCustomer({
    required String rawPhone,
    required String name,
  }) async {
    final normalizedPhone = PhoneHelper.normalize(rawPhone);

    if (normalizedPhone.isEmpty) {
      throw Exception('Nomor telepon tidak valid: $rawPhone');
    }

    final existing = await _firestoreService.getUserByPhone(normalizedPhone);

    if (existing != null) return existing;

    final newId = await getNextUserId();

    final guest = UserModel(
      userId: newId,
      name: name.trim(),
      username: null,
      password: null,
      phone: normalizedPhone,
      address: null,
      fcmToken: null,
      role: 'Customer',
    );

    await _firestoreService.addUser(guest);

    return guest;
  }

  Future<void> createOrder({
    required UserModel customer,
    required int cashierId,
    required ServiceModel service,
    required int weight,
    required int totalAmount,
    required String paymentMethod,
    required String notes,
    int? generatedOrderId,
    String? generatedOrderCode,
  }) async {
    if (weight <= 0) {
      throw Exception('Weight harus lebih dari 0 kg');
    }

    if (totalAmount <= 0) {
      throw Exception('Total amount harus lebih dari 0');
    }

    if (!allowedPaymentMethods.contains(paymentMethod)) {
      throw Exception('Payment method tidak valid');
    }

    final orderId = generatedOrderId ?? await getNextOrderId();

    final orderCode =
        generatedOrderCode ?? 'ORD${orderId.toString().padLeft(3, '0')}';

    final order = LaundryOrderModel(
      orderId: orderId,
      orderCode: orderCode,
      userId: customer.userId,
      createdBy: cashierId,
      orderDate: Timestamp.now(),
      totalWeight: weight,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      notes: notes.trim(),
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