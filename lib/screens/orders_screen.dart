import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class OrdersScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const OrdersScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No orders yet',
                      style: GoogleFonts.lora(fontSize: 18, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Start shopping from local farmers',
                      style: GoogleFonts.raleway(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: cart.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = cart.orders[index];
              return _OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return AppColors.warning;
      case 'CONFIRMED': return AppColors.accent;
      case 'DELIVERED': return AppColors.success;
      case 'CANCELLED': return AppColors.destructive;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List<dynamic>? ?? [];
    final farmer = order['farmer'] as Map<String, dynamic>? ?? {};
    final status = order['status'] as String? ?? 'PENDING';
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order['orderNo'] as String? ?? order['id'] as String? ?? '',
                  style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status,
                    style: GoogleFonts.raleway(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(item['productEmoji'] as String? ?? '🥕', style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item['productName']} × ${(item['quantity'] as num?)?.toInt() ?? 0}',
                    style: GoogleFonts.raleway(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          )),
          const Divider(color: AppColors.border, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(farmer['farmName'] as String? ?? '',
                  style: GoogleFonts.raleway(fontSize: 12, color: AppColors.textMuted)),
              Text('₹${total.toStringAsFixed(0)}',
                  style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}
