import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../viewmodels/customer_dashboard_viewmodel.dart';

class CustomerDashboardPage extends StatelessWidget {
  final UserModel user;

  const CustomerDashboardPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = CustomerDashboardViewModel();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
      ),
      body: FutureBuilder(
        future: viewModel.getCustomerOrders(user.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                Text(
                  'Hello, ${user.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Your Laundry Orders'),
                const SizedBox(height: 20),

                if (orders.isEmpty)
                  const Center(
                    child: Text('No orders found'),
                  ),

                for (var order in orders)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_laundry_service),
                      title: Text(order.orderCode),
                      subtitle: Text(
                        'Status: ${order.status}\nWeight: ${order.totalWeight} kg',
                      ),
                      trailing: Text('Rp ${order.totalAmount}'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}