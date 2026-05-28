class ServiceModel {
  final int serviceId;
  final String serviceName;
  final int estimatedDays;
  final String description;
  final bool isActive;

  ServiceModel({
    required this.serviceId,
    required this.serviceName,
    required this.estimatedDays,
    required this.description,
    required this.isActive,
  });

  factory ServiceModel.fromFirestore(Map<String, dynamic> data) {
    return ServiceModel(
      serviceId: data['service_id'],
      serviceName: data['service_name'],
      estimatedDays: data['estimated_days'],
      description: data['description'],
      isActive: data['is_active'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'service_id': serviceId,
      'service_name': serviceName,
      'estimated_days': estimatedDays,
      'description': description,
      'is_active': isActive,
    };
  }
}