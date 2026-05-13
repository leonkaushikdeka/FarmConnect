import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service for handling Razorpay payment operations.
///
/// This class provides methods to:
/// 1. Create a Razorpay order on the backend
/// 2. Verify payment signature with the backend
///
/// Usage:
/// ```dart
/// final paymentService = PaymentService();
/// paymentService.setToken(authToken);
///
/// final order = await paymentService.createRazorpayOrder(orderId, amount);
/// // Open Razorpay checkout with order.orderId, order.amount, etc.
///
/// final verified = await paymentService.verifyPayment(
///   razorpayOrderId, paymentId, signature);
/// ```
class PaymentService {
  final ApiService _api = ApiService();

  void setToken(String? token) {
    _api.setToken(token);
  }

  /// Creates a Razorpay order by calling the backend API.
  ///
  /// [orderId] - The internal database order ID (e.g., "ORD001")
  /// [amount] - The order amount in rupees
  ///
  /// Returns a map containing:
  /// - orderId: Razorpay order ID
  /// - amount: Amount in paise (smallest currency unit)
  /// - currency: Currency code (e.g., "INR")
  /// - key: Razorpay API key ID
  Future<Map<String, dynamic>> createRazorpayOrder(
    String orderId,
    double amount,
  ) async {
    return _api.post('/payments/create-order', {
      'orderId': orderId,
      'amount': amount,
      'currency': 'INR',
    });
  }

  /// Verifies a Razorpay payment with the backend.
  ///
  /// [razorpayOrderId] - The Razorpay order ID
  /// [razorpayPaymentId] - The Razorpay payment ID
  /// [razorpaySignature] - The Razorpay signature
  ///
  /// Returns the verification result including the updated order info.
  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return _api.post('/payments/verify', {
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    });
  }
}