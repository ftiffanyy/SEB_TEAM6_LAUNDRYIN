import '../models/laundry_order_model.dart';
import '../services/firestore_service.dart';

class EmployeeDashboardViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final List<LaundryOrderModel> orders = await _firestoreService.getOrders();

    int totalOrders = orders.length;
    int totalRevenue = 0;
    int completedOrders = 0;
    int activeOrders = 0;

    for (var order in orders) {
      totalRevenue += order.totalAmount;

      if (order.status.toLowerCase() == 'completed') {
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
}