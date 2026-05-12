import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name'] as String? ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final unit = product['unit'] as String? ?? 'kg';
    final emoji = product['emoji'] as String? ?? '🥕';
    final organic = product['organic'] as bool? ?? false;
    final inSeason = product['inSeason'] as bool? ?? false;
    final farmer = product['farmer'] as Map<String, dynamic>? ?? {};
    final farmName = farmer['farmName'] as String? ?? 'Farm';
    final location = farmer['address'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (organic)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Organic',
                              style: GoogleFonts.raleway(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.accent)),
                        ),
                      if (inSeason) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('In Season',
                              style: GoogleFonts.raleway(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.warning)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(name,
                      style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.foreground),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$farmName · ${location.split(",").first}',
                      style: GoogleFonts.raleway(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₹${price.toStringAsFixed(0)}',
                              style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          Text('/ $unit',
                              style: GoogleFonts.raleway(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                      Material(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: onAddToCart,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.add_shopping_cart_outlined, color: AppColors.onPrimary, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
