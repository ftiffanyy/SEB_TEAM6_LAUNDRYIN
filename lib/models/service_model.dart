class ServiceModel {
  final int serviceId;
  final String serviceName;
  final int estimatedDays;
  final int servicePrice;
  final String description;
  final bool isActive;

  ServiceModel({
    required this.serviceId,
    required this.serviceName,
    required this.estimatedDays,
    required this.servicePrice,
    required this.description,
    required this.isActive,
  });

  factory ServiceModel.fromFirestore(Map<String, dynamic> data) {
    return ServiceModel(
      serviceId: data['service_id'] ?? 0,
      serviceName: data['service_name'] ?? '',
      estimatedDays: data['estimated_days'] ?? 0,
      servicePrice: data['service_price'] ?? 0,
      description: data['description'] ?? '',
      isActive: data['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'service_id': serviceId,
      'service_name': serviceName,
      'estimated_days': estimatedDays,
      'service_price': servicePrice,
      'description': description,
      'is_active': isActive,
    };
  }
}