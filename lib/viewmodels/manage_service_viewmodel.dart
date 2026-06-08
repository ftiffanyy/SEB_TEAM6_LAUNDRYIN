import '../models/service_model.dart';
import '../services/firestore_service.dart';

class ManageServiceViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<ServiceModel>> getServices() async {
    return await _firestoreService.getServices();
  }

  Future<int> getNextServiceId() async {
    final services = await _firestoreService.getServices();

    if (services.isEmpty) return 1;

    final maxId = services
        .map((service) => service.serviceId)
        .reduce((a, b) => a > b ? a : b);

    return maxId + 1;
  }

  Future<void> addService({
    required String serviceName,
    required int estimatedDays,
    required int servicePrice,
    required String description,
  }) async {
    final serviceId = await getNextServiceId();

    final service = ServiceModel(
      serviceId: serviceId,
      serviceName: serviceName,
      estimatedDays: estimatedDays,
      servicePrice: servicePrice,
      description: description,
      isActive: true,
    );

    await _firestoreService.addService(service);
  }

  Future<void> updateService(ServiceModel service) async {
    await _firestoreService.updateService(service);
  }

  Future<void> toggleServiceStatus(ServiceModel service) async {
    final updatedService = ServiceModel(
      serviceId: service.serviceId,
      serviceName: service.serviceName,
      estimatedDays: service.estimatedDays,
      servicePrice: service.servicePrice,
      description: service.description,
      isActive: !service.isActive,
    );

    await _firestoreService.updateService(updatedService);
  }
}