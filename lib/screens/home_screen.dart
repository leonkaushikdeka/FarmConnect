import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import '../widgets/farmer_card.dart';
import '../widgets/cart_badge.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'farmer_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsProv = context.watch<ProductsProvider>();
    final cart = context.watch<CartProvider>();

    final filtered = productsProv.products.where((p) {
      if (_selectedCategory != 'All' && p['category'] != _selectedCategory) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (p['name'] as String).toLowerCase();
        final farm = (p['farmer']?['farmName'] as String? ?? '').toLowerCase();
        return name.contains(q) || farm.contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Farm',
                style: GoogleFonts.lora(
                  fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary,
                ),
              ),
              TextSpan(
                text: 'Connect',
                style: GoogleFonts.lora(
                  fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CartBadge(
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => productsProv.refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fresh from the farm\nto your doorstep',
                      style: GoogleFonts.lora(
                        fontSize: 28, fontWeight: FontWeight.w700,
                        color: AppColors.foreground, height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search produce, farmers...',
                        prefixIcon: const Icon(Icons.search_outlined, color: AppColors.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: productsProv.categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final label = index == 0 ? 'All' : productsProv.categories[index - 1];
                    return CategoryChip(
                      label: label,
                      selected: _selectedCategory == label,
                      onTap: () => setState(() => _selectedCategory = label),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            if (productsProv.farmers.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Featured Farmers',
                          style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                      TextButton(onPressed: () {}, child: const Text('View all')),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: productsProv.farmers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final f = productsProv.farmers[index];
                      final user = f['user'] as Map<String, dynamic>? ?? {};
                      return SizedBox(
                        width: 280,
                        child: FarmerCard(
                          farmer: f,
                          farmerName: user['name'] as String? ?? '',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FarmerProfileScreen(
                                farmerId: f['id'] as String,
                                farmerName: f['farmName'] as String,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _selectedCategory == 'All' ? 'All Produce' : _selectedCategory,
                  style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (productsProv.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = filtered[index];
                      return ProductCard(
                        product: p,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: p),
                          ),
                        ),
                        onAddToCart: () {
                          cart.addToCartFromApi(p);
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
                    childCount: filtered.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
