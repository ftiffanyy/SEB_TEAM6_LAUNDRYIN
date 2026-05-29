import 'package:flutter/material.dart';

import '../../models/service_model.dart';
import '../../viewmodels/manage_service_viewmodel.dart';

class ManageServicePage extends StatefulWidget {
  const ManageServicePage({super.key});

  @override
  State<ManageServicePage> createState() => _ManageServicePageState();
}

class _ManageServicePageState extends State<ManageServicePage> {
  final ManageServiceViewModel viewModel = ManageServiceViewModel();

  final serviceNameController = TextEditingController();
  final estimatedDaysController = TextEditingController();
  final descriptionController = TextEditingController();

  List<ServiceModel> services = [];
  bool isLoading = true;
  bool isSaving = false;
  String message = '';

  ServiceModel? editingService;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    final data = await viewModel.getServices();

    setState(() {
      services = data;
      isLoading = false;
    });
  }

  void openServiceForm({ServiceModel? service}) {
    editingService = service;

    if (service != null) {
      serviceNameController.text = service.serviceName;
      estimatedDaysController.text = service.estimatedDays.toString();
      descriptionController.text = service.description;
    } else {
      serviceNameController.clear();
      estimatedDaysController.clear();
      descriptionController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return serviceFormSheet();
      },
    );
  }

  Future<void> saveService() async {
    if (serviceNameController.text.trim().isEmpty ||
        estimatedDaysController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      setState(() {
        message = 'Semua field harus diisi';
      });
      return;
    }

    setState(() {
      isSaving = true;
      message = '';
    });

    try {
      if (editingService == null) {
        await viewModel.addService(
          serviceName: serviceNameController.text.trim(),
          estimatedDays: int.parse(estimatedDaysController.text.trim()),
          description: descriptionController.text.trim(),
        );
      } else {
        final updatedService = ServiceModel(
          serviceId: editingService!.serviceId,
          serviceName: serviceNameController.text.trim(),
          estimatedDays: int.parse(estimatedDaysController.text.trim()),
          description: descriptionController.text.trim(),
          isActive: editingService!.isActive,
        );

        await viewModel.updateService(updatedService);
      }

      setState(() {
        isSaving = false;
        message = editingService == null
            ? 'Service berhasil ditambahkan'
            : 'Service berhasil diupdate';
      });

      Navigator.pop(context);

      await loadServices();
    } catch (e) {
      setState(() {
        isSaving = false;
        message = 'Error: $e';
      });
    }
  }

  Future<void> toggleStatus(ServiceModel service) async {
    await viewModel.toggleServiceStatus(service);
    await loadServices();
  }

  @override
  void dispose() {
    serviceNameController.dispose();
    estimatedDaysController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeServices = services.where((s) => s.isActive).toList();
    final inactiveServices = services.where((s) => !s.isActive).toList();

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        title: const Text('Manage Services'),
        backgroundColor: const Color(0xff4A90E2),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff4A90E2),
        foregroundColor: Colors.white,
        onPressed: () => openServiceForm(),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                headerCard(),
                const SizedBox(height: 20),

                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: message.startsWith('Error')
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                sectionTitle('Active Services'),
                const SizedBox(height: 10),

                if (activeServices.isEmpty)
                  emptyText('No active services'),

                ...activeServices.map((service) {
                  return serviceCard(service);
                }),

                const SizedBox(height: 24),

                sectionTitle('Inactive Services'),
                const SizedBox(height: 10),

                if (inactiveServices.isEmpty)
                  emptyText('No inactive services'),

                ...inactiveServices.map((service) {
                  return serviceCard(service);
                }),
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
          Icon(
            Icons.local_laundry_service,
            color: Colors.white,
            size: 42,
          ),
          SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Add, edit, and manage laundry services',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget emptyText(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget serviceCard(ServiceModel service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor:
              service.isActive ? const Color(0xffEAF3FF) : Colors.grey.shade200,
          child: Icon(
            Icons.cleaning_services,
            color: service.isActive
                ? const Color(0xff4A90E2)
                : Colors.grey,
          ),
        ),
        title: Text(
          service.serviceName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${service.estimatedDays} day(s)\n${service.description}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              openServiceForm(service: service);
            } else if (value == 'toggle') {
              toggleStatus(service);
            }
          },
          itemBuilder: (context) {
            return [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Text(
                  service.isActive ? 'Deactivate' : 'Activate',
                ),
              ),
            ];
          },
        ),
      ),
    );
  }

  Widget serviceFormSheet() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xffF4F7FB),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              editingService == null ? 'Add New Service' : 'Edit Service',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            inputField(
              controller: serviceNameController,
              label: 'Service Name',
              icon: Icons.cleaning_services,
              isNumber: false,
            ),

            inputField(
              controller: estimatedDaysController,
              label: 'Estimated Days',
              icon: Icons.calendar_today,
            ),

            inputField(
              controller: descriptionController,
              label: 'Description',
              icon: Icons.description,
              isNumber: false,
              maxLines: 3,
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: isSaving ? null : saveService,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isSaving
                    ? 'Saving...'
                    : editingService == null
                        ? 'Add Service'
                        : 'Update Service',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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