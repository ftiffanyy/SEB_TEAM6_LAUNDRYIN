import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/customer_dashboard_viewmodel.dart';

class CustomerOrderDetailPage extends StatelessWidget {
  final CustomerOrderItem item;

  const CustomerOrderDetailPage({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final order = item.order;
    final date = order.orderDate.toDate();
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        title: const Text('Order Detail'),
        backgroundColor: const Color(0xff4A90E2),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatusBanner(order.status),
          const SizedBox(height: 20),

          _buildSectionLabel('Order Info'),
          const SizedBox(height: 10),
          _buildCard([
            _buildRow(Icons.tag, 'Order Code', order.orderCode),
            _buildDivider(),
            _buildRow(Icons.calendar_today, 'Date', formattedDate),
            _buildDivider(),
            _buildRow(Icons.info_outline, 'Status', order.status),
          ]),
          const SizedBox(height: 20),

          _buildSectionLabel('Service Details'),
          const SizedBox(height: 10),
          _buildCard([
            _buildRow(Icons.local_laundry_service, 'Service', item.serviceName),
            _buildDivider(),
            _buildRow(
              Icons.monitor_weight_outlined,
              'Weight',
              '${order.totalWeight} kg',
            ),
            _buildDivider(),
            _buildRow(
              Icons.payments_outlined,
              'Price per kg',
              item.servicePrice == 0
                  ? '-'
                  : 'Rp ${_formatRupiah(item.servicePrice)}',
            ),
            _buildDivider(),
            _buildRow(
              Icons.schedule,
              'Estimated',
              item.estimatedDays == 0
                  ? '-'
                  : '${item.estimatedDays} day${item.estimatedDays > 1 ? 's' : ''}',
            ),
          ]),
          const SizedBox(height: 20),

          if (order.notes.isNotEmpty) ...[
            _buildSectionLabel('Notes'),
            const SizedBox(height: 10),
            _buildCard([
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes,
                        color: Color(0xff4A90E2), size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        order.notes,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),
          ],

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xff185FA5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    color: Color(0xffB5D4F4),
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Rp ${_formatRupiah(order.totalAmount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'washed':
        bg = const Color(0xffE6F1FB);
        fg = const Color(0xff185FA5);
        icon = Icons.local_laundry_service;
        break;
      case 'ironed':
        bg = const Color(0xffFBEAF0);
        fg = const Color(0xff993556);
        icon = Icons.iron;
        break;
      case 'ready':
      case 'ready to pickup':
        bg = const Color(0xffE1F5EE);
        fg = const Color(0xff0F6E56);
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
      case 'picked up':
        bg = const Color(0xffEAF3DE);
        fg = const Color(0xff3B6D11);
        icon = Icons.task_alt;
        break;
      case 'received':
      default:
        bg = const Color(0xffFAEEDA);
        fg = const Color(0xff854F0B);
        icon = Icons.timelapse;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: fg, size: 44),
          const SizedBox(height: 10),
          Text(
            status,
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff4A90E2), size: 20),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(
      height: 1,
      indent: 50,
      endIndent: 16,
      color: Colors.grey.shade200);

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}