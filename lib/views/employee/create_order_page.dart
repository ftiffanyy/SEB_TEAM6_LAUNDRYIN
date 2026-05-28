import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../viewmodels/create_order_viewmodel.dart';

class CreateOrderPage extends StatefulWidget {
  final UserModel employee;

  const CreateOrderPage({
    super.key,
    required this.employee,
  });

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final customerIdController = TextEditingController();
  final serviceIdController = TextEditingController();
  final weightController = TextEditingController();
  final totalAmountController = TextEditingController();
  final notesController = TextEditingController();

  final viewModel = CreateOrderViewModel();

  bool isLoading = false;
  String message = '';

  Future<void> submitOrder() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      await viewModel.createOrder(
        customerId: int.parse(customerIdController.text),
        cashierId: widget.employee.userId,
        serviceId: int.parse(serviceIdController.text),
        weight: int.parse(weightController.text),
        totalAmount: int.parse(totalAmountController.text),
        notes: notesController.text,
      );

      setState(() {
        isLoading = false;
        message = 'Order berhasil dibuat';
      });

      customerIdController.clear();
      serviceIdController.clear();
      weightController.clear();
      totalAmountController.clear();
      notesController.clear();
    } catch (e) {
      setState(() {
        isLoading = false;
        message = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    customerIdController.dispose();
    serviceIdController.dispose();
    weightController.dispose();
    totalAmountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            inputField(customerIdController, 'Customer ID'),
            inputField(serviceIdController, 'Service ID'),
            inputField(weightController, 'Weight'),
            inputField(totalAmountController, 'Total Amount'),
            inputField(notesController, 'Notes'),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: isLoading ? null : submitOrder,
              child: Text(isLoading ? 'Saving...' : 'Create Order'),
            ),

            const SizedBox(height: 16),

            if (message.isNotEmpty)
              Text(
                message,
                style: TextStyle(
                  color: message.startsWith('Error') ? Colors.red : Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget inputField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: label == 'Notes' ? TextInputType.text : TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}