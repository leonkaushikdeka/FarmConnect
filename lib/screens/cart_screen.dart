import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('Your cart is empty',
                      style: GoogleFonts.lora(fontSize: 18, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Browse produce from local farmers',
                      style: GoogleFonts.raleway(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(14)),
                            child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 28))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                                Text('₹${item.price.toStringAsFixed(0)} / ${item.unit}',
                                    style: GoogleFonts.raleway(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _QtyBtn(
                                icon: Icons.remove,
                                onTap: () => cart.updateQuantity(item.productId, item.quantity - 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  item.quantity == item.quantity.roundToDouble()
                                      ? item.quantity.toInt().toString()
                                      : item.quantity.toStringAsFixed(1),
                                  style: GoogleFonts.raleway(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground),
                                ),
                              ),
                              _QtyBtn(
                                icon: Icons.add,
                                onTap: () => cart.updateQuantity(item.productId, item.quantity + 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                          Text('₹${cart.totalPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                          child: const Text('Proceed to Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppColors.foreground),
      ),
    );
  }
}
