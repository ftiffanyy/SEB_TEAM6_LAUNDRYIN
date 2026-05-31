import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/service_model.dart';
import '../models/laundry_order_model.dart';
import '../models/order_detail_model.dart';
import '../services/firestore_service.dart';
import '../utils/phone_helper.dart';

class CreateOrderViewModel {
  final FirestoreService _firestoreService = FirestoreService();

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

  Future<int> getNextUserId() async {
    final users = await _firestoreService.getUsers();
    if (users.isEmpty) return 1;

    return users
            .map((e) => e.userId)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  /// Cari user by phone dulu, baru buat jika belum ada
  Future<UserModel> findOrCreateCustomer({
    required String rawPhone,
    required String name,
  }) async {
    // 1. Normalize & validasi phone
    final normalizedPhone = PhoneHelper.normalize(rawPhone);
    if (normalizedPhone.isEmpty) {
      throw Exception('Nomor telepon tidak valid: $rawPhone');
    }

    // 2. Cek apakah phone sudah terdaftar
    final existing = await _firestoreService.getUserByPhone(normalizedPhone);
    if (existing != null) return existing;

    // 3. Belum ada → buat guest user baru
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
    required String notes,
  }) async {
    final orderId = await getNextOrderId();
    final orderCode = 'ORD${orderId.toString().padLeft(3, '0')}';

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