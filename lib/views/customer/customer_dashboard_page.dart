import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../viewmodels/customer_dashboard_viewmodel.dart';
import 'customer_order_detail_page.dart';
// TODO: Sesuaikan path import login_page.dart ini dengan struktur folder Anda
import '../../views/auth/login_page.dart'; 

class CustomerDashboardPage extends StatefulWidget {
  final UserModel user;

  const CustomerDashboardPage({
    super.key,
    required this.user,
  });

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  final CustomerDashboardViewModel viewModel = CustomerDashboardViewModel();
  Future<List<CustomerOrderItem>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _ordersFuture = viewModel.getCustomerOrderItems(widget.user.userId);
    });
  }

  // Fungsi untuk menampilkan dialog konfirmasi logout
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out of your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Tutup dialog
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                // Pindah ke LoginPage dan hapus semua stack halaman sebelumnya
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xff4A90E2),
        foregroundColor: Colors.white,
        // Menambahkan tombol logout di AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<CustomerOrderItem>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allItems = snapshot.data ?? [];
          final activeItems = viewModel.getActiveOrders(allItems);
          final completedItems = viewModel.getCompletedOrders(allItems);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildGreeting(),
                const SizedBox(height: 20),
                _buildStatsRow(allItems.length, activeItems.length, completedItems.length),
                const SizedBox(height: 24),
                _buildSectionLabel('Active Orders'),
                const SizedBox(height: 12),
                if (activeItems.isEmpty)
                  _buildEmptyState('No active orders')
                else
                  _buildOrderCard(activeItems),
                const SizedBox(height: 24),
                _buildSectionLabel('Completed Orders'),
                const SizedBox(height: 12),
                if (completedItems.isEmpty)
                  _buildEmptyState('No completed orders')
                else
                  _buildOrderCard(completedItems),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Greeting ────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    final initials = widget.user.name
        .trim()
        .split(' ')
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xffB5D4F4),
          child: Text(
            initials,
            style: const TextStyle(
              color: Color(0xff0C447C),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${widget.user.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Track your laundry orders below.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Stats ───────────────────────────────────────────────────────────────

  Widget _buildStatsRow(int total, int active, int completed) {
    return Row(
      children: [
        Expanded(child: _statCard('Total', total.toString(), 'All time', null)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Active', active.toString(), 'In progress', const Color(0xff185FA5))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Done', completed.toString(), 'Completed', const Color(0xff3B6D11))),
      ],
    );
  }

  Widget _statCard(String label, String value, String sub, Color? valueColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
          Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  // ─── Order card ───────────────────────────────────────────────────────────

  Widget _buildOrderCard(List<CustomerOrderItem> items) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerOrderDetailPage(item: item),
                ),
              );
              _refresh();
            },
            child: _buildOrderTile(item, i < items.length - 1),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderTile(CustomerOrderItem item, bool showDivider) {
    final order = item.order;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xffE6F1FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_laundry_service,
                    color: Color(0xff185FA5), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderCode,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${order.totalWeight} kg · ${item.serviceName}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp ${_formatRupiah(order.totalAmount)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ),
        if (showDivider)
          Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey.shade200),
      ],
    );
  }

  // ─── Status badge ─────────────────────────────────────────────────────────

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'washing':
        bg = const Color(0xffE6F1FB);
        fg = const Color(0xff185FA5);
        break;
      case 'ready':
      case 'ready to pickup':
        bg = const Color(0xffE1F5EE);
        fg = const Color(0xff0F6E56);
        break;
      case 'completed':
      case 'picked up':
        bg = const Color(0xffEAF3DE);
        fg = const Color(0xff3B6D11);
        break;
      case 'processing':
      default:
        bg = const Color(0xffFAEEDA);
        fg = const Color(0xff854F0B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}