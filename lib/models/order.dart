import 'product.dart';

enum OrderStatus { pending, confirmed, delivered, cancelled }

class Order {
  final String id;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<MapEntry<Product, double>> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.total,
    this.status = OrderStatus.pending,
    required this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
