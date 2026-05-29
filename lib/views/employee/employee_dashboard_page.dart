import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/laundry_order_model.dart';
import '../../viewmodels/employee_dashboard_viewmodel.dart';
import 'create_order_page.dart';
import 'update_status_page.dart';
import 'manage_service_page.dart';

class EmployeeDashboardPage extends StatefulWidget {
  final UserModel user;

  const EmployeeDashboardPage({
    super.key,
    required this.user,
  });

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  final EmployeeDashboardViewModel viewModel = EmployeeDashboardViewModel();

  Future<Map<String, dynamic>>? dashboardFuture;

  @override
  void initState() {
    super.initState();
    refreshDashboard();
  }

  void refreshDashboard() {
    dashboardFuture = viewModel.getDashboardSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        backgroundColor: const Color(0xff4A90E2),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};

          final List<LaundryOrderModel> orders =
              data['orders'] as List<LaundryOrderModel>? ?? [];

          final activeOrders = orders.where((order) {
            return order.status.toLowerCase() != 'completed';
          }).toList();

          final completedOrders = orders.where((order) {
            return order.status.toLowerCase() == 'completed';
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                Text(
                  'Welcome, ${widget.user.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Role: ${widget.user.role}'),
                const SizedBox(height: 20),

                orderExpansionCard(
                  title: 'Total Orders',
                  value: data['totalOrders'].toString(),
                  icon: Icons.receipt_long,
                  orders: orders,
                ),

                orderExpansionCard(
                  title: 'Active Orders',
                  value: data['activeOrders'].toString(),
                  icon: Icons.timelapse,
                  orders: activeOrders,
                ),

                orderExpansionCard(
                  title: 'Completed Orders',
                  value: data['completedOrders'].toString(),
                  icon: Icons.check_circle,
                  orders: completedOrders,
                ),

                summaryCard(
                  'Total Revenue',
                  'Rp ${data['totalRevenue']}',
                  Icons.payments,
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

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.add_box),
                    title: const Text('Create Order'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateOrderPage(
                            employee: widget.user,
                          ),
                        ),
                      );

                      setState(() {
                        refreshDashboard();
                      });
                    },
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.update),
                    title: const Text('Update Laundry Status'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateStatusPage(
                            employee: widget.user,
                          ),
                        ),
                      );

                      setState(() {
                        refreshDashboard();
                      });
                    },
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_laundry_service),
                    title: const Text('Manage Services'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageServicePage(),
                        ),
                      );

                      setState(() {
                        refreshDashboard();
                      });
                    },
                  ),
                ),

                if (widget.user.role == 'Admin')
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

  Widget orderExpansionCard({
    required String title,
    required String value,
    required IconData icon,
    required List<LaundryOrderModel> orders,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: const Color(0xff4A90E2)),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No orders found'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Order Code')),
                  DataColumn(label: Text('Weight')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Status')),
                ],
                rows: orders.map((order) {
                  return DataRow(
                    cells: [
                      DataCell(Text(order.orderCode)),
                      DataCell(Text('${order.totalWeight} kg')),
                      DataCell(Text('Rp ${order.totalAmount}')),
                      DataCell(Text(order.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget summaryCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xff4A90E2)),
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