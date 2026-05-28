import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/service_model.dart';
import '../models/laundry_order_model.dart';
import '../models/order_detail_model.dart';

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

  Future<void> addOrderDetail(OrderDetailModel detail) async {
    await _db
        .collection('order_details')
        .doc('detail_${detail.orderDetailId}')
        .set(detail.toFirestore());
  }
}