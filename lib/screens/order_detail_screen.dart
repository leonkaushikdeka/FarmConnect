import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Order Detail Screen — displays full order information.
/// Triggered when a user taps a push notification.
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      _order = await _api.get('/orders/${widget.orderId}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load order: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : _buildOrderDetails(),
    );
  }

  Widget _buildOrderDetails() {
    final order = _order!;
    final status = order['status'] as String? ?? 'PENDING';
    final orderNo = order['orderNo'] as String? ?? '';
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];
    final farmer = order['farmer'] as Map<String, dynamic>? ?? {};

    Color _statusColor(String s) {
      switch (s) {
        case 'PENDING': return Colors.orange;
        case 'CONFIRMED': return Colors.blue;
        case 'PACKING': return Colors.purple;
        case 'OUT_FOR_DELIVERY': return Colors.teal;
        case 'DELIVERED': return Colors.green;
        case 'CANCELLED': return Colors.red;
        default: return Colors.grey;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number
          Text(
            orderNo,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: _statusColor(status),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Order items
          Text(
            'Items',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(
                    item['productEmoji'] as String? ?? '🥕',
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(item['productName'] as String? ?? ''),
                  subtitle: Text(
                    '${item['quantity']?.toString() ?? ''} × ${item['unit'] ?? ''}',
                  ),
                  trailing: Text(
                    '₹${((item['price'] as num?) ?? 0) * ((item['quantity'] as num?) ?? 0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )),
          const SizedBox(height: 16),

          // Farmer info
          if (farmer.isNotEmpty) ...[
            Text(
              'Farmer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: Text(farmer['farmName'] as String? ?? ''),
                subtitle: Text(farmer['address'] as String? ?? ''),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Total
          Divider(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669))),
            ],
          ),
        ],
      ),
    );
  }
}