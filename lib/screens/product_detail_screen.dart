import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'farmer_profile_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final name = p['name'] as String? ?? '';
    final price = (p['price'] as num?)?.toDouble() ?? 0;
    final unit = p['unit'] as String? ?? 'kg';
    final emoji = p['emoji'] as String? ?? '🥕';
    final organic = p['organic'] as bool? ?? false;
    final inSeason = p['inSeason'] as bool? ?? false;
    final description = p['description'] as String? ?? '';
    final quantity = (p['quantity'] as num?)?.toDouble() ?? 0;
    final farmer = p['farmer'] as Map<String, dynamic>? ?? {};
    final farmName = farmer['farmName'] as String? ?? 'Farm';
    final farmerId = farmer['id'] as String? ?? '';
    final farmerLoc = farmer['address'] as String? ?? '';
    final farmerUser = farmer['user'] as Map<String, dynamic>? ?? {};
    final farmerPersonName = farmerUser['name'] as String? ?? 'Farmer';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 280,
              color: AppColors.muted,
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 96))),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (organic) _Badge(label: 'Organic', color: AppColors.accent),
                    if (inSeason) ...[const SizedBox(width: 6), _Badge(label: 'In Season', color: AppColors.warning)],
                  ]),
                  const SizedBox(height: 12),
                  Text(name, style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('₹${price.toStringAsFixed(0)}',
                          style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const SizedBox(width: 4),
                      Text('/ $unit', style: GoogleFonts.raleway(fontSize: 16, color: AppColors.textMuted)),
                      const Spacer(),
                      Text('$quantity $unit available',
                          style: GoogleFonts.raleway(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  Text('Description',
                      style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                  const SizedBox(height: 8),
                  Text(description,
                      style: GoogleFonts.raleway(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  Text('Sold by',
                      style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: farmerId.isNotEmpty
                        ? () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => FarmerProfileScreen(farmerId: farmerId, farmerName: farmName)))
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                            child: Text(farmerPersonName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                                style: GoogleFonts.raleway(fontWeight: FontWeight.w600, color: AppColors.accent)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(farmName,
                                    style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                                Text(farmerLoc.split(',').first,
                                    style: GoogleFonts.raleway(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<CartProvider>().addToCartFromApi(p);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name added to cart'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: const Text('Add to Cart'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.raleway(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
