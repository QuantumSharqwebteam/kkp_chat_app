import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';

class MarketingProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository;

  MarketingProductProvider(this._productRepository);

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
    } catch (e) {
      _allProducts = [];
      _filteredProducts = [];
      // optionally save error state here
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
