import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/user_model.dart';
import '../../utils/file_export_helper.dart';
import '../../models/laundry_order_model.dart';
import '../../viewmodels/employee_dashboard_viewmodel.dart';
import 'create_order_page.dart';
import 'update_status_page.dart';
import 'manage_service_page.dart';
import 'manage_user_page.dart';

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

  DateTime? _fromDate;
  DateTime? _toDate;
  Map<String, dynamic>? _filteredReport;
  bool _isFiltering = false;

  Future<Map<String, dynamic>>? dashboardFuture;

  @override
  void initState() {
    super.initState();
    refreshDashboard();
  }

  void refreshDashboard() {
    dashboardFuture = viewModel.getDashboardSummary();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _shareTempFile(String filename, Uint8List bytes, String label) async {
    if (kIsWeb) {
      saveFileWeb(filename, bytes, 'application/octet-stream');
      _showSnack('$label downloaded to browser');
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: label);
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

                // Admin-only reporting controls
                if (widget.user.role == 'Admin') ...[
                  const Text(
                    'Reporting',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 140,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _fromDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );

                                    if (picked != null) {
                                      setState(() => _fromDate = picked);
                                    }
                                  },
                                  child: Text(_fromDate == null
                                      ? 'From'
                                      : DateFormat('yyyy-MM-dd').format(_fromDate!)),
                                ),
                              ),
                              SizedBox(
                                width: 140,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _toDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );

                                    if (picked != null) {
                                      setState(() => _toDate = picked);
                                    }
                                  },
                                  child: Text(_toDate == null
                                      ? 'To'
                                      : DateFormat('yyyy-MM-dd').format(_toDate!)),
                                ),
                              ),
                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: _isFiltering
                                      ? null
                                      : () async {
                                          if (_fromDate == null || _toDate == null) {
                                            _showSnack('Please select both from and to dates');
                                            return;
                                          }

                                          setState(() => _isFiltering = true);

                                          try {
                                            final report = await viewModel.getFilteredReport(
                                              DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day),
                                              DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59),
                                            );

                                            setState(() {
                                              _filteredReport = report;
                                            });

                                            _showSnack('Filter applied');
                                          } catch (e) {
                                            _showSnack('Filter failed: $e');
                                          } finally {
                                            setState(() => _isFiltering = false);
                                          }
                                        },
                                  child: const Text('Apply Filter'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: (_filteredReport == null || (_filteredReport?['orders'] as List).isEmpty)
                                      ? null
                                      : () async {
                                          final orders = _filteredReport!['orders'] as List<dynamic>;
                                          final csv = viewModel.generateCsv(List<LaundryOrderModel>.from(orders));
                                          final bytes = Uint8List.fromList(csv.codeUnits);
                                          if (kIsWeb) {
                                            saveFileWeb('report_${DateTime.now().millisecondsSinceEpoch}.csv', bytes, 'text/csv');
                                            _showSnack('CSV download started in browser');
                                            return;
                                          }

                                          await _shareTempFile('report_${DateTime.now().millisecondsSinceEpoch}.csv', bytes, 'Laporan CSV');
                                        },
                                  child: const Text('Export CSV'),
                                ),
                              ),
                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: (_filteredReport == null || (_filteredReport?['orders'] as List).isEmpty)
                                      ? null
                                      : () async {
                                          final orders = List<LaundryOrderModel>.from(_filteredReport!['orders'] as List<dynamic>);
                                          try {
                                            final bytes = await viewModel.generatePdfBytes(orders);
                                            if (kIsWeb) {
                                              saveFileWeb('report_${DateTime.now().millisecondsSinceEpoch}.pdf', bytes, 'application/pdf');
                                              _showSnack('PDF download started in browser');
                                              return;
                                            }

                                            await _shareTempFile('report_${DateTime.now().millisecondsSinceEpoch}.pdf', bytes, 'Laporan PDF');
                                          } catch (e) {
                                            _showSnack('Export PDF failed: $e');
                                          }
                                        },
                                  child: const Text('Export PDF'),
                                ),
                              ),
                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: (_filteredReport == null || (_filteredReport?['orders'] as List).isEmpty)
                                      ? null
                                      : () async {
                                          final orders = List<LaundryOrderModel>.from(_filteredReport!['orders'] as List<dynamic>);
                                          try {
                                            final bytes = await viewModel.generateExcelBytes(orders);
                                            if (kIsWeb) {
                                              saveFileWeb('report_${DateTime.now().millisecondsSinceEpoch}.xlsx', bytes, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
                                              _showSnack('Excel download started in browser');
                                              return;
                                            }

                                            await _shareTempFile('report_${DateTime.now().millisecondsSinceEpoch}.xlsx', bytes, 'Laporan Excel');
                                          } catch (e) {
                                            _showSnack('Export Excel failed: $e');
                                          }
                                        },
                                  child: const Text('Export Excel'),
                                ),
                              ),
                            ],
                          ),

                          if (_filteredReport != null) ...[
                            const SizedBox(height: 12),
                            Text('Report: ${_filteredReport!['totalOrders']} orders, Rp ${_filteredReport!['totalRevenue']}'),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],

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
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageUserPage(),
                        ),
                      );
                    },
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
    String title, {
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}