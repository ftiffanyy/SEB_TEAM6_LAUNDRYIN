import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/service_model.dart';
import '../models/laundry_order_model.dart';
import '../models/order_detail_model.dart';
import '../models/status_history_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =========================
  // USERS
  // =========================

  Future<void> addUser(UserModel user) async {
    await _db
        .collection('users')
        .doc('user_${user.userId}')
        .set(user.toFirestore());
  }

  Future<List<UserModel>> getUsers() async {
    final snapshot = await _db.collection('users').get();

    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data()))
        .toList();
  }

  // =========================
  // SERVICES
  // =========================

  Future<void> addService(ServiceModel service) async {
    await _db
        .collection('services')
        .doc('service_${service.serviceId}')
        .set(service.toFirestore());
  }

  Future<List<ServiceModel>> getServices() async {
    final snapshot = await _db.collection('services').get();

    return snapshot.docs
        .map((doc) => ServiceModel.fromFirestore(doc.data()))
        .toList();
  }

  Future<void> updateService(ServiceModel service) async {
    final snapshot = await _db
        .collection('services')
        .where('service_id', isEqualTo: service.serviceId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update(service.toFirestore());
    }
  }

  // =========================
  // ORDERS
  // =========================

  Future<void> addOrder(LaundryOrderModel order) async {
    await _db
        .collection('laundry_orders')
        .doc('order_${order.orderId}')
        .set(order.toFirestore());
  }

  Future<List<LaundryOrderModel>> getOrders() async {
    final snapshot = await _db.collection('laundry_orders').get();

    return snapshot.docs
        .map((doc) => LaundryOrderModel.fromFirestore(doc.data()))
        .toList();
  }

  Future<List<OrderDetailModel>> getOrderDetails() async {
    final snapshot =
        await _db.collection('order_details').get();

    return snapshot.docs
        .map(
          (doc) => OrderDetailModel.fromFirestore(
            doc.data(),
          ),
        )
        .toList();
}

  Future<void> addOrderDetail(OrderDetailModel detail) async {
    await _db
        .collection('order_details')
        .doc('detail_${detail.orderDetailId}')
        .set(detail.toFirestore());
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final snapshot = await _db
        .collection('laundry_orders')
        .where('order_id', isEqualTo: orderId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'status': status,
      });
    }
  }

  Future<List<StatusHistoryModel>> getStatusHistories() async {
    final snapshot = await _db.collection('status_history').get();

    return snapshot.docs
        .map((doc) => StatusHistoryModel.fromFirestore(doc.data()))
        .toList();
  }

  Future<void> addStatusHistory(StatusHistoryModel statusHistory) async {
    await _db
        .collection('status_history')
        .doc('status_${statusHistory.statusHistoryId}')
        .set(statusHistory.toFirestore());
  }
}