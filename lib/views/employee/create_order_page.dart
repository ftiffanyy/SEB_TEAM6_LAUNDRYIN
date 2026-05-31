import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../models/service_model.dart';
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
  final viewModel = CreateOrderViewModel();

  final customerSearchController = TextEditingController();
  final newCustomerPhoneController = TextEditingController();
  final weightController = TextEditingController();
  final totalAmountController = TextEditingController();
  final notesController = TextEditingController();

  UserModel? selectedCustomer;
  ServiceModel? selectedService;

  List<UserModel> customers = [];
  List<ServiceModel> services = [];
  bool isLoading = true;
  bool isSaving = false;
  bool addNewCustomer = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    loadData();

    weightController.addListener(() {
      calculateTotalAmount();
    });
  }

  int getPricePerKg(int serviceId) {
    switch (serviceId) {
      case 1:
        return 10000;
      case 2:
        return 25000; // 10k + 15k
      case 3:
        return 25000; // 10k + 15k
      case 4:
        return 5000;
      case 5:
        return 15000;
      default:
        return 0;
    }
  }

  void calculateTotalAmount() {
    if (selectedService == null || weightController.text.isEmpty) {
      totalAmountController.text = '';
      return;
    }

    final weight = int.tryParse(weightController.text) ?? 0;
    final pricePerKg = getPricePerKg(selectedService!.serviceId);
    final total = weight * pricePerKg;

    totalAmountController.text = total.toString();
  }

  Future<void> loadData() async {
    final customerData = await viewModel.getCustomers();
    final serviceData = await viewModel.getServices();

    setState(() {
      customers = customerData;
      services = serviceData;
      isLoading = false;
    });
  }

  Future<void> submitOrder() async {
    if (selectedService == null) {
      setState(() => message = 'Pilih service dulu');
      return;
    }

    if (customerSearchController.text.trim().isEmpty) {
      setState(() => message = 'Isi nama customer dulu');
      return;
    }

    if (weightController.text.trim().isEmpty) {
      setState(() => message = 'Isi weight dulu');
      return;
    }

    setState(() {
      isSaving = true;
      message = '';
    });

    try {
      UserModel customer;

      if (addNewCustomer) {
        customer = await viewModel.findOrCreateCustomer(
          name: customerSearchController.text.trim(),
          rawPhone: newCustomerPhoneController.text.trim(),
        );
      } else {
        if (selectedCustomer == null) {
          setState(() {
            isSaving = false;
            message =
                'Pilih customer dari hasil search atau aktifkan Add New Customer';
          });
          return;
        }
        customer = selectedCustomer!;
      }

      await viewModel.createOrder(
        customer: customer,
        cashierId: widget.employee.userId,
        service: selectedService!,
        weight: int.parse(weightController.text),
        totalAmount: int.parse(totalAmountController.text),
        notes: notesController.text,
      );

      setState(() {
        isSaving = false;
        message = 'Order berhasil dibuat';
        selectedCustomer = null;
        selectedService = null;
        addNewCustomer = false;
      });

      customerSearchController.clear();
      newCustomerPhoneController.clear();
      weightController.clear();
      totalAmountController.clear();
      notesController.clear();

      await loadData();
    } catch (e) {
      setState(() {
        isSaving = false;
        message = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    customerSearchController.dispose();
    newCustomerPhoneController.dispose();
    weightController.dispose();
    totalAmountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchText = customerSearchController.text.toLowerCase();

    final filteredCustomers = customers.where((customer) {
      final name = customer.name.toLowerCase();
      final phone = customer.phone.toLowerCase();

      return name.contains(searchText) || phone.contains(searchText);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        title: const Text('Create Order'),
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
                      'Customer Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: customerSearchController,
                      onChanged: (_) {
                        setState(() {
                          selectedCustomer = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Search by Customer Name / Phone Number',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    if (!addNewCustomer &&
                        customerSearchController.text.isNotEmpty)
                      ...filteredCustomers.map((customer) {
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(customer.name),
                          subtitle: Text(customer.phone),
                          onTap: () {
                            setState(() {
                              selectedCustomer = customer;
                              customerSearchController.text = customer.name;
                            });
                          },
                        );
                      }),

                    SwitchListTile(
                      value: addNewCustomer,
                      title: const Text('Add New Customer'),
                      subtitle: const Text('For customer not in database'),
                      onChanged: (value) {
                        setState(() {
                          addNewCustomer = value;
                          selectedCustomer = null;
                        });
                      },
                    ),

                    if (addNewCustomer)
                      TextField(
                        controller: newCustomerPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Customer Phone Number',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                formCard(
                  children: [
                    const Text(
                      'Order Detail',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<ServiceModel>(
                      value: selectedService,
                      decoration: InputDecoration(
                        labelText: 'Select Service',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: services.map((service) {
                        return DropdownMenuItem(
                          value: service,
                          child: Text(service.serviceName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedService = value;
                          calculateTotalAmount();
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    inputField(weightController, 'Weight (kg)', Icons.scale),

                    TextField(
                      controller: totalAmountController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Total Amount',
                        prefixIcon: const Icon(Icons.payments),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    inputField(
                      notesController,
                      'Notes',
                      Icons.note,
                      isNumber: false,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: isSaving ? null : submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(isSaving ? 'Saving...' : 'Create Order'),
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
          Icon(Icons.add_shopping_cart, color: Colors.white, size: 42),
          SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Laundry Order',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Create customer laundry transaction',
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
      child: Column(children: children),
    );
  }

  Widget inputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}