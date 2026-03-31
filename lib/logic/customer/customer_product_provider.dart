import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';

class CustomerProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CustomerProductProvider() {
    loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final productRepository = ProductRepository();
      final fetchedProducts = await productRepository.getProducts();
      await LocalDbHelper.saveProducts(fetchedProducts);
      _products = fetchedProducts;
      _filteredProducts = _products; // Initialize filtered products
      _isLoading = false;
      notifyListeners();
      debugPrint("📦 Products loaded: ${_products.length}");
    } catch (e) {
      _error = 'Failed to load products: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter products based on search query
  void filterProducts(String query) {
    _searchQuery = query.toLowerCase();
    _filteredProducts = _searchQuery.isEmpty
        ? _products
        : _products
            .where((product) => product.productName.toLowerCase().contains(_searchQuery))
            .toList();
    notifyListeners();
    debugPrint("🔍 Filtered products count: ${_filteredProducts.length}");
  }

  // Refresh products from Hive (not API)
  Future<void> refreshProductsFromHive() async {
    try {
      debugPrint("🔄 [CustomerProductProvider] Refreshing products from Hive...");
      _products = await LocalDbHelper.getProducts();
      filterProducts(_searchQuery); // Reapply the current filter
      debugPrint("✅ [CustomerProductProvider] Products refreshed from Hive!");
    } catch (e) {
      _error = 'Failed to refresh products from cache: $e';
      notifyListeners();
      debugPrint("❌ [CustomerProductProvider] Failed to refresh products: $e");
    }
  }

  // Force refresh from API
  Future<void> refreshProducts() async {
    await loadProducts();
  }
}
