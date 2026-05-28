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
      orderDetailId: data['order_detail_id'],
      orderId: data['order_id'],
      serviceId: data['service_id'],
      weight: (data['weight']).toDouble(),
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