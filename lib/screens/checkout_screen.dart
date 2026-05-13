import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
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
  final _addressController =
      TextEditingController(text: '123, MG Road, Bangalore - 560001');
  String _paymentMethod = 'COD';
  bool _isProcessing = false;

  late Razorpay _razorpay;
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    // Listen for Razorpay payment callbacks
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  /// -------------------------------------------------------
  /// Razorpay callback handlers
  /// -------------------------------------------------------

  /// Called when Razorpay payment succeeds.
  /// Verifies the payment signature with our backend,
  /// then places the order.
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      setState(() => _isProcessing = true);

      final cart = context.read<CartProvider>();

      // Verify the payment with the backend
      final verifyResult = await _paymentService.verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (verifyResult['success'] == true) {
        // Payment verified — place the order via the backend API
        // using the orderId from our earlier create-order call.
        final orderData = await _placeBackendOrder(
          paymentMethod: _paymentMethod,
          razorpayPaymentId: response.paymentId,
          razorpayOrderId: response.orderId,
        );

        if (orderData != null) {
          cart.clearCart();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => _OrderSuccessScreen(
                        orderNo: orderData['orderNo'] ?? 'N/A',
                      )),
              (route) => route.isFirst,
            );
          }
        }
      } else {
        _showErrorSnackBar('Payment verification failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Called when Razorpay reports a payment error.
  void _handlePaymentError(PaymentFailureResponse response) {
    _showErrorSnackBar(
        'Payment failed: ${response.message ?? 'Unknown error'}');
  }

  /// Called when user selects an external wallet option.
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected: ${response.walletName}');
  }

  /// -------------------------------------------------------
  /// Order placement helpers
  /// -------------------------------------------------------

  /// Places the order on the backend with paid status.
  Future<Map<String, dynamic>?> _placeBackendOrder({
    required String paymentMethod,
    required String? razorpayPaymentId,
    required String? razorpayOrderId,
  }) async {
    final cart = context.read<CartProvider>();

    try {
      final order = await ApiService().post('/orders', {
        'farmerId': cart.items.first.farmerId,
        'items': cart.items
            .map((item) => {
                  'productId': item.productId,
                  'quantity': item.quantity,
                })
            .toList(),
        'deliveryAddress': _addressController.text,
        'customerPhone': _phoneController.text,
        'customerName': _nameController.text,
        'paymentMethod': paymentMethod,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpayOrderId': razorpayOrderId,
      });

      return order;
    } catch (e) {
      debugPrint('Order placement error: $e');
      _showErrorSnackBar('Failed to place order. Contact support.');
      return null;
    }
  }

  /// -------------------------------------------------------
  /// Razorpay checkout flow trigger
  /// -------------------------------------------------------

  /// Creates a Razorpay order on the backend and opens the checkout.
  Future<void> _startRazorpayCheckout() async {
    try {
      setState(() => _isProcessing = true);

      final cart = context.read<CartProvider>();
      final totalInRupees = cart.totalPrice;

      // Step 1: Place a pending order on the backend to get an orderId
      final orderData = await ApiService().post('/orders', {
        'farmerId': cart.items.first.farmerId,
        'items': cart.items
            .map((item) => {
                  'productId': item.productId,
                  'quantity': item.quantity,
                })
            .toList(),
        'deliveryAddress': _addressController.text,
        'customerPhone': _phoneController.text,
        'customerName': _nameController.text,
        'paymentMethod': _paymentMethod,
      });

      final backendOrderId = orderData['id'] as String;

      // Step 2: Create a Razorpay order on the backend
      final razorpayOrder =
          await _paymentService.createRazorpayOrder(backendOrderId, totalInRupees);

      // Step 3: Open Razorpay checkout
      final options = {
        'key': razorpayOrder['key'],         // Razorpay API Key ID
        'amount': razorpayOrder['amount'],   // Amount in paise
        'currency': razorpayOrder['currency'] ?? 'INR',
        'order_id': razorpayOrder['orderId'], // Razorpay order ID
        'name': 'FarmConnect',
        'description': 'Purchase of farm-fresh produce',
        'prefill': {
          'contact': _phoneController.text,
          'email': '', // Optionally fill from user profile
        },
        'external': {
          'wallets': ['paytm'],
        },
      };

      _razorpay.open(options);
    } catch (e) {
      _showErrorSnackBar('Failed to initialize payment: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// -------------------------------------------------------
  /// UI
  /// -------------------------------------------------------

  bool get _isCardOrUpi =>
      _paymentMethod == 'CARD' || _paymentMethod == 'UPI';

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
            // ---- Delivery Details ----
            Text('Delivery Details',
                style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline)),
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  prefixIcon: Icon(Icons.location_on_outlined)),
              maxLines: 3,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // ---- Payment Method ----
            Text('Payment Method',
                style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground)),
            const SizedBox(height: 8),
            _PaymentOption(
              label: 'Cash on Delivery',
              value: 'COD',
              icon: Icons.money,
              selected: _paymentMethod,
              onSelect: (v) {
                if (v != null) setState(() => _paymentMethod = v);
              },
            ),
            const SizedBox(height: 4),
            _PaymentOption(
              label: 'UPI (Google Pay / PhonePe)',
              value: 'UPI',
              icon: Icons.phone_android,
              selected: _paymentMethod,
              onSelect: (v) {
                if (v != null) setState(() => _paymentMethod = v);
              },
            ),
            const SizedBox(height: 4),
            _PaymentOption(
              label: 'Card / Net Banking',
              value: 'CARD',
              icon: Icons.credit_card,
              selected: _paymentMethod,
              onSelect: (v) {
                if (v != null) setState(() => _paymentMethod = v);
              },
            ),

            // ---- Razorpay note ----
            if (_isCardOrUpi) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security,
                        size: 20, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You will be redirected to Razorpay for secure payment.',
                        style: GoogleFonts.raleway(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ---- Order Summary ----
            Text('Order Summary',
                style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground)),
            const SizedBox(height: 12),
            ...cart.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(item.emoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(item.name,
                              style: GoogleFonts.raleway(
                                  color: AppColors.foreground))),
                      Text(
                          '${item.quantity.toInt()} × ₹${item.price.toStringAsFixed(0)}',
                          style: GoogleFonts.raleway(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                )),
            const Divider(color: AppColors.border, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: GoogleFonts.lora(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground)),
                Text('₹${cart.totalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.lora(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 24),

            // ---- Place Order Button ----
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isProcessing)
                    ? null
                    : () {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        if (_isCardOrUpi) {
                          // Razorpay flow for CARD / UPI
                          _startRazorpayCheckout();
                        } else {
                          // COD — use existing direct placement
                          _placeOrderCod(cart);
                        }
                      },
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ))
                    : Text(
                        _isCardOrUpi ? 'Pay Securely' : 'Place Order',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// COD order placement (original behavior).
  void _placeOrderCod(CartProvider cart) {
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
}

// ---- Sub-widgets ----

class _PaymentOption extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String selected;
  final ValueChanged<String?> onSelect;

  const _PaymentOption({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.muted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: selected,
        onChanged: onSelect,
        title: Text(label,
            style: TextStyle(fontSize: 14, color: AppColors.foreground)),
        activeColor: AppColors.accent,
      ),
    );
  }
}

class _OrderSuccessScreen extends StatelessWidget {
  final String? orderNo;
  const _OrderSuccessScreen({this.orderNo});

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
                decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.accent),
              ),
              const SizedBox(height: 24),
              Text('Order Placed!',
                  style: GoogleFonts.lora(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground)),
              const SizedBox(height: 8),
              Text(orderNo != null ? 'Order #$orderNo' : '',
                  style: GoogleFonts.raleway(
                      fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text('Your farmer will confirm soon.\nFresh produce is on its way!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
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