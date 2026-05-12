import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Demo User');
  final _phoneController = TextEditingController(text: '+91-9876543210');
  final _addressController = TextEditingController(text: '123, MG Road, Bangalore - 560001');
  String _paymentMethod = 'COD';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Delivery Details',
                style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Delivery Address', prefixIcon: Icon(Icons.location_on_outlined)),
              maxLines: 3,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            Text('Payment Method',
                style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground)),
            const SizedBox(height: 8),
            _PaymentOption(label: 'Cash on Delivery', value: 'COD', icon: Icons.money, selected: _paymentMethod, onSelect: (v) { if (v != null) setState(() => _paymentMethod = v); }),
            const SizedBox(height: 4),
            _PaymentOption(label: 'UPI (Google Pay / PhonePe)', value: 'UPI', icon: Icons.phone_android, selected: _paymentMethod, onSelect: (v) { if (v != null) setState(() => _paymentMethod = v); }),
            const SizedBox(height: 4),
            _PaymentOption(label: 'Card / Net Banking', value: 'CARD', icon: Icons.credit_card, selected: _paymentMethod, onSelect: (v) { if (v != null) setState(() => _paymentMethod = v); }),
            const SizedBox(height: 24),
            Text('Order Summary',
                style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground)),
            const SizedBox(height: 12),
            ...cart.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.name, style: GoogleFonts.raleway(color: AppColors.foreground))),
                  Text('${item.quantity.toInt()} × ₹${item.price.toStringAsFixed(0)}',
                      style: GoogleFonts.raleway(color: AppColors.textSecondary)),
                ],
              ),
            )),
            const Divider(color: AppColors.border, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                Text('₹${cart.totalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    cart.placeOrder(
                      customerName: _nameController.text,
                      customerPhone: _phoneController.text,
                      deliveryAddress: _addressController.text,
                      farmerId: cart.items.first.farmerId,
                      paymentMethod: _paymentMethod,
                    );
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const _OrderSuccessScreen()),
                      (route) => route.isFirst,
                    );
                  }
                },
                child: const Text('Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String selected;
  final ValueChanged<String?> onSelect;
  const _PaymentOption({required this.label, required this.value, required this.icon, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent.withValues(alpha: 0.08) : AppColors.muted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
      ),
        child: RadioListTile<String>(
        value: value,
        groupValue: selected,
        onChanged: onSelect,
        title: Text(label, style: TextStyle(fontSize: 14, color: AppColors.foreground)),
        activeColor: AppColors.accent,
      ),
    );
  }
}

class _OrderSuccessScreen extends StatelessWidget {
  const _OrderSuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Placed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, size: 64, color: AppColors.accent),
              ),
              const SizedBox(height: 24),
              Text('Order Placed!',
                  style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground)),
              const SizedBox(height: 8),
              Text('Your farmer will confirm soon.\nFresh produce is on its way!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
