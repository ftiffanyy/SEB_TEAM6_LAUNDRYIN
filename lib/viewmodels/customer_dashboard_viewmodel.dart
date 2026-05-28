import '../models/laundry_order_model.dart';
import '../services/firestore_service.dart';

class CustomerDashboardViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<LaundryOrderModel>> getCustomerOrders(int userId) async {
    final orders = await _firestoreService.getOrders();

    return orders.where((order) => order.userId == userId).toList();
  }
}