class OrderDetailModel {
  final int orderDetailId;
  final int orderId;
  final int serviceId;
  final double weight;

  OrderDetailModel({
    required this.orderDetailId,
    required this.orderId,
    required this.serviceId,
    required this.weight,
  });

  factory OrderDetailModel.fromFirestore(Map<String, dynamic> data) {
    return OrderDetailModel(
      orderDetailId: data['order_detail_id'] ?? 0,
      orderId: data['order_id'] ?? 0,
      serviceId: data['service_id'] ?? 0,
      weight: (data['weight'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'order_detail_id': orderDetailId,
      'order_id': orderId,
      'service_id': serviceId,
      'weight': weight,
    };
  }
}