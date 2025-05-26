import 'package:flutter/foundation.dart';

import 'package:kkpchatapp/data/models/product_model.dart';
import 'fake_product_repository.dart';

class FakeMarketingProductProvider extends ChangeNotifier {
  final FakeProductRepository _productRepository;

  FakeMarketingProductProvider(this._productRepository);

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = "";

  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allProducts = await _productRepository.getProducts();
      applyFilter(_searchQuery);
    } catch (_) {
      _allProducts = [];
      _filteredProducts = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void applyFilter(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = _allProducts
          .where((product) =>
              product.productName.toLowerCase().contains(_searchQuery))
          .toList();
    }
    notifyListeners();
  }
}
