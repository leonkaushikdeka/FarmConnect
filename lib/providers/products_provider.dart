import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ProductsProvider extends ChangeNotifier {
  final ApiService _api;

  List<dynamic> _products = [];
  List<dynamic> _farmers = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;

  ProductsProvider(this._api);

  List<dynamic> get products => _products;
  List<dynamic> get farmers => _farmers;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts({String? category, String? search, String? farmerId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final query = <String, String>{};
      if (category != null && category != 'All') query['category'] = category;
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (farmerId != null) query['farmerId'] = farmerId;

      _products = await _api.getList('/products', query: query);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load products';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFarmers({String? search}) async {
    try {
      final query = <String, String>{};
      if (search != null && search.isNotEmpty) query['search'] = search;
      _farmers = await _api.getList('/farmers', query: query);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadCategories() async {
    try {
      final res = await _api.getList('/products/categories');
      _categories = res.cast<String>();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refresh() async {
    await Future.wait([
      loadProducts(),
      loadFarmers(),
      loadCategories(),
    ]);
  }
}
