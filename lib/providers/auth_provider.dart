import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String _userRole = '';
  String _userId = '';
  String? _error;
  Map<String, dynamic>? _farmer;

  AuthProvider(this._api);

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isFarmer => _userRole == 'FARMER';
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userRole => _userRole;
  String get userId => _userId;
  String? get error => _error;
  Map<String, dynamic>? get farmer => _farmer;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });
      _api.setToken(res['token'] as String);
      final user = res['user'] as Map<String, dynamic>;
      _userId = user['id'] as String;
      _userName = user['name'] as String;
      _userEmail = user['email'] as String;
      _userRole = user['role'] as String;
      _farmer = res['farmer'] as Map<String, dynamic>?;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      // Register FCM token with the backend
      await sendTokenToBackend();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Using offline mode.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerCustomer(String name, String email, String password, String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post('/auth/register/customer', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      });
      _api.setToken(res['token'] as String);
      final user = res['user'] as Map<String, dynamic>;
      _userId = user['id'] as String;
      _userName = user['name'] as String;
      _userEmail = user['email'] as String;
      _userRole = user['role'] as String;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      await sendTokenToBackend();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerFarmer({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String farmName,
    required String description,
    required String address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post('/auth/register/farmer', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'farmName': farmName,
        'description': description,
        'address': address,
      });
      _api.setToken(res['token'] as String);
      final user = res['user'] as Map<String, dynamic>;
      _userId = user['id'] as String;
      _userName = user['name'] as String;
      _userEmail = user['email'] as String;
      _userRole = user['role'] as String;
_farmer = res['farmer'] as Map<String, dynamic>?;
       _isLoggedIn = true;
       _isLoading = false;
       notifyListeners();
       await sendTokenToBackend();
       return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _api.setToken(null);
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    _userRole = '';
    _userId = '';
    _farmer = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
