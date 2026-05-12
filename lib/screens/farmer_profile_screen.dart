import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class FarmerProfileScreen extends StatefulWidget {
  final String farmerId;
  final String farmerName;

  const FarmerProfileScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
  });

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  Map<String, dynamic>? _farmer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final prov = context.read<ProductsProvider>();
    for (final f in prov.farmers) {
      if (f['id'] == widget.farmerId) {
        setState(() => _farmer = f);
        break;
      }
    }
    prov.loadProducts(farmerId: widget.farmerId);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductsProvider>();
    final products = prov.products.where((p) {
      final f = p['farmer'] as Map<String, dynamic>? ?? {};
      return f['id'] == widget.farmerId;
    }).toList();

    final f = _farmer;
    final name = f?['farmName'] as String? ?? widget.farmerName;
    final farmerUser = f?['user'] as Map<String, dynamic>? ?? {};
    final farmerPersonName = farmerUser['name'] as String? ?? 'Farmer';
    final desc = f?['description'] as String? ?? '';
    final address = f?['address'] as String? ?? '';
    final rating = (f?['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (f?['reviewCount'] as num?)?.toInt() ?? 0;
    final phone = f?['phone'] as String? ?? '';
    final certs = (f?['certifications'] as List<dynamic>?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                        child: Text(
                          name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                          style: GoogleFonts.raleway(fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                            Text(farmerPersonName,
                                style: GoogleFonts.raleway(fontSize: 14, color: AppColors.textSecondary)),
                            Row(children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(address.split(',').first,
                                    style: GoogleFonts.raleway(fontSize: 12, color: AppColors.textMuted)),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Row(children: [
                            const Icon(Icons.star, size: 18, color: AppColors.rating),
                            Text(rating.toStringAsFixed(1),
                                style: GoogleFonts.raleway(fontWeight: FontWeight.w600, color: AppColors.foreground)),
                          ]),
                          Text('($reviewCount reviews)',
                              style: GoogleFonts.raleway(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(desc, style: GoogleFonts.raleway(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                  ],
                  if (certs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: certs.map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(c,
                            style: GoogleFonts.raleway(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
                      )).toList(),
                    ),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(phone, style: GoogleFonts.raleway(fontSize: 13, color: AppColors.accent)),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  Text('Products',
                      style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = products[index];
                  return ProductCard(
                    product: p,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                    ),
                    onAddToCart: () {
                      context.read<CartProvider>().addToCartFromApi(p);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${p['name']} added to cart'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
