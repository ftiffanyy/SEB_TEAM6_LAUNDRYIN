import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../viewmodels/employee_dashboard_viewmodel.dart';
import 'create_order_page.dart';

class EmployeeDashboardPage extends StatelessWidget {
  final UserModel user;

  const EmployeeDashboardPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = EmployeeDashboardViewModel();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: viewModel.getDashboardSummary(),
        builder: (context, snapshot) {
          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ERROR
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          final data = snapshot.data ?? {};

          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                // WELCOME
                Text(
                  'Welcome, ${user.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text('Role: ${user.role}'),

                const SizedBox(height: 20),

                // SUMMARY
                summaryCard(
                  'Total Orders',
                  data['totalOrders'].toString(),
                ),

                summaryCard(
                  'Active Orders',
                  data['activeOrders'].toString(),
                ),

                summaryCard(
                  'Completed Orders',
                  data['completedOrders'].toString(),
                ),

                summaryCard(
                  'Total Revenue',
                  'Rp ${data['totalRevenue']}',
                ),

                const SizedBox(height: 24),

                const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // CREATE ORDER
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.add_box),
                    title: const Text('Create Order'),
                    trailing: const Icon(Icons.arrow_forward_ios),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateOrderPage(
                            employee: user,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // PAYMENT
                menuCard(
                  Icons.payment,
                  'Process Payment',
                ),

                // UPDATE STATUS
                menuCard(
                  Icons.update,
                  'Update Laundry Status',
                ),

                // SERVICES
                menuCard(
                  Icons.local_laundry_service,
                  'Manage Services',
                ),

                // ADMIN ONLY
                if (user.role == 'Admin')
                  menuCard(
                    Icons.people,
                    'Manage Users',
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================
  // SUMMARY CARD
  // =========================

  Widget summaryCard(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),

        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // =========================
  // MENU CARD
  // =========================

  Widget menuCard(
    IconData icon,
    String title,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}