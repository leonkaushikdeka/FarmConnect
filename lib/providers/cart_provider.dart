import 'package:flutter/foundation.dart';

class CartItemData {
  final String productId;
  final String name;
  final String emoji;
  final double price;
  final String unit;
  final String farmerName;
  final String farmerId;
  double quantity;

  CartItemData({
    required this.productId,
    required this.name,
    required this.emoji,
    required this.price,
    required this.unit,
    required this.farmerName,
    required this.farmerId,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItemData> _items = [];
  final List<Map<String, dynamic>> _orders = [];
  int _orderCounter = 0;

  List<CartItemData> get items => List.unmodifiable(_items);
  List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);
  int get itemCount => _items.length;
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addToCartFromApi(Map<String, dynamic> product) {
    final id = product['id'] as String;
    final index = _items.indexWhere((i) => i.productId == id);
    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      final farmer = product['farmer'] as Map<String, dynamic>? ?? {};
      _items.add(CartItemData(
        productId: id,
        name: product['name'] as String? ?? '',
        emoji: product['emoji'] as String? ?? '🥕',
        price: (product['price'] as num?)?.toDouble() ?? 0,
        unit: product['unit'] as String? ?? 'kg',
        farmerName: farmer['farmName'] as String? ?? '',
        farmerId: farmer['id'] as String? ?? '',
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, double quantity) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  Map<String, dynamic> placeOrder({
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required String farmerId,
    String paymentMethod = 'COD',
  }) {
    _orderCounter++;
    final order = <String, dynamic>{
      'id': 'ORD${_orderCounter.toString().padLeft(4, '0')}',
      'orderNo': 'FC${DateTime.now().millisecondsSinceEpoch}',
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'totalAmount': totalPrice,
      'paymentMethod': paymentMethod,
      'status': 'PENDING',
      'createdAt': DateTime.now().toIso8601String(),
      'items': _items.map((i) => {
        'productName': i.name,
        'productEmoji': i.emoji,
        'price': i.price,
        'quantity': i.quantity,
        'unit': i.unit,
      }).toList(),
      'farmer': {'farmName': _items.first.farmerName},
    };
    _orders.insert(0, order);
    _items.clear();
    notifyListeners();
    return order;
  }
}
