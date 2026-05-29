import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import '../../viewmodels/update_status_viewmodel.dart';

class UpdateStatusPage extends StatefulWidget {
  final UserModel employee;

  const UpdateStatusPage({
    super.key,
    required this.employee,
  });

  @override
  State<UpdateStatusPage> createState() => _UpdateStatusPageState();
}

class _UpdateStatusPageState extends State<UpdateStatusPage> {
  final UpdateStatusViewModel viewModel = UpdateStatusViewModel();
  final searchController = TextEditingController();
  final notesController = TextEditingController();

  List<OrderStatusItem> orderItems = [];
  OrderStatusItem? selectedItem;
  String? selectedStatus;

  bool isLoading = true;
  bool isSaving = false;
  String message = '';

  final List<String> statusOptions = [
    'Received',
    'Washed',
    'Ironed',
    'Completed',
    'Picked Up',
  ];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    final data = await viewModel.getOrderStatusItems();

    setState(() {
      orderItems = data;
      isLoading = false;
    });
  }

  Future<void> submitStatus() async {
    if (selectedItem == null) {
      setState(() => message = 'Pilih order dulu');
      return;
    }

    if (selectedStatus == null) {
      setState(() => message = 'Pilih status baru dulu');
      return;
    }

    setState(() {
      isSaving = true;
      message = '';
    });

    try {
      await viewModel.updateStatus(
        order: selectedItem!.order,
        newStatus: selectedStatus!,
        changedBy: widget.employee.userId,
        notes: notesController.text.trim(),
      );

      setState(() {
        isSaving = false;
        message = 'Status berhasil diupdate';
        selectedItem = null;
        selectedStatus = null;
      });

      searchController.clear();
      notesController.clear();

      await loadOrders();
    } catch (e) {
      setState(() {
        isSaving = false;
        message = 'Error: $e';
      });
    }
  }

  String formatDate(dynamic timestamp) {
    try {
      final date = timestamp.toDate();
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return '-';
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchText = searchController.text.toLowerCase();

    final filteredItems = orderItems.where((item) {
      return item.order.orderCode.toLowerCase().contains(searchText) ||
          item.customerName.toLowerCase().contains(searchText) ||
          item.serviceName.toLowerCase().contains(searchText) ||
          item.order.status.toLowerCase().contains(searchText) ||
          item.order.orderId.toString().contains(searchText);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        title: const Text('Update Laundry Status'),
        backgroundColor: const Color(0xff4A90E2),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                headerCard(),
                const SizedBox(height: 20),

                formCard(
                  children: [
                    const Text(
                      'Find Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: searchController,
                      onChanged: (_) {
                        setState(() {
                          selectedItem = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText:
                            'Search by Order Code / Customer / Service / Status',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (searchController.text.isNotEmpty)
                      ...filteredItems.map((item) {
                        return orderTile(item);
                      }),

                    if (searchController.text.isNotEmpty &&
                        filteredItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No order found'),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                if (selectedItem != null)
                  formCard(
                    children: [
                      const Text(
                        'Selected Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      selectedOrderCard(),

                      const SizedBox(height: 18),

                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Select New Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      buildTimeline(
                        selectedStatus ?? selectedItem!.order.status,
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          prefixIcon: const Icon(Icons.note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: isSaving ? null : submitStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(isSaving ? 'Saving...' : 'Update Status'),
                ),

                if (message.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          message.startsWith('Error') ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget orderTile(OrderStatusItem item) {
    final order = item.order;

    return ListTile(
      leading: const Icon(Icons.local_laundry_service),
      title: Text(order.orderCode),
      subtitle: Text(
        '${item.customerName} • ${item.serviceName}\n'
        'Status: ${order.status} • Weight: ${order.totalWeight} kg',
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        setState(() {
          selectedItem = item;
          selectedStatus = order.status;
          searchController.text = order.orderCode;
        });
      },
    );
  }

  Widget selectedOrderCard() {
    final item = selectedItem!;
    final order = item.order;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffEAF3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffD5E6FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_laundry_service,
                  color: Color(0xff4A90E2),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      order.status,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          infoRow(Icons.person, 'Customer', item.customerName),
          infoRow(Icons.cleaning_services, 'Service', item.serviceName),
          infoRow(Icons.calendar_today, 'Order Date', formatDate(order.orderDate)),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: infoBox(
                  'Weight',
                  '${order.totalWeight} kg',
                  Icons.scale,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: infoBox(
                  'Amount',
                  'Rp ${order.totalAmount}',
                  Icons.payments,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xff4A90E2),
          ),
          const SizedBox(width: 8),
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget infoBox(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xff4A90E2),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimeline(String currentStatus) {
    final statuses = [
      'Received',
      'Washed',
      'Ironed',
      'Completed',
      'Picked Up',
    ];

    final currentIndex = statuses.indexOf(currentStatus);

    return Row(
      children: List.generate(statuses.length, (index) {
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isCompleted
                    ? Colors.green
                    : isCurrent
                        ? Colors.orange
                        : Colors.grey.shade300,
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : isCurrent
                          ? Icons.radio_button_checked
                          : Icons.circle,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                statuses[index],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff4A90E2), Color(0xff6BB6FF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.update, color: Colors.white, size: 42),
          SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Manage laundry progress',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget formCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}