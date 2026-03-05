import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';

class MarketingProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository;

  // ✅ ADDED: Logger instance
  final LoggingService _logger = LoggingService.instance;

  MarketingProductProvider(this._productRepository);

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = "";

  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  bool _isRefreshing = false; // ✅ NEW (already present)
  bool get isRefreshing => _isRefreshing;

  Future<void> fetchProducts({bool isRefresh = false}) async {
    // ✅ Differentiate initial load vs pull refresh
    if (isRefresh) {
      _isRefreshing = true; // AppBar loader ON
      _logger.logUi(
        'Refreshing products from AppBar',
        level: LogLevel.info,
      ); // ✅ ADDED
    } else {
      _isLoading = true; // Full shimmer loader
      _logger.logUi(
        'Initial product load started',
        level: LogLevel.info,
      ); // ✅ ADDED
    }
    notifyListeners();

    try {
      // ✅ ADDED: Before API call log
      _logger.logUi(
        'Calling ProductRepository.getProducts()',
        level: LogLevel.debug,
      );

      _allProducts = await _productRepository.getProducts();
      await LocalDbHelper.saveProducts(_allProducts);

      // ✅ ADDED: Log response data count
      _logger.logUi(
        'Products fetched successfully | Count: ${_allProducts.length}',
        level: LogLevel.info,
      );

      // ✅ ADDED: Optional detailed log (first few items only)
      if (_allProducts.isNotEmpty) {
        _logger.logUi(
          'Sample product response: ${_allProducts.take(3).map((e) => e.productName).toList()}',
          level: LogLevel.debug,
        );
      }

      applyFilter(_searchQuery);
    } catch (e, stackTrace) {
      // ✅ ADDED: Error logging
      _logger.logUi(
        'Error while fetching products in MarketingProductProvider',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );

      _allProducts = [];
      try {
        _allProducts = await LocalDbHelper.getProducts();
        _logger.logUi(
          'Loaded products from local cache | Count: ${_allProducts.length}',
          level: LogLevel.warning,
        );
      } catch (_) {
        _allProducts = [];
      }
      _filteredProducts = [];
    }

    _isLoading = false;
    _isRefreshing = false; // AppBar loader OFF

    // // ✅ ADDED: End state log
    // _logger.logUi(
    //   'Product fetch completed | Loading: $_isLoading | Refreshing: $_isRefreshing',
    //   level: LogLevel.debug,
    // );

    notifyListeners();
  }

  Future<void> refreshProductsFromHive() async {
    try {
      _allProducts = await LocalDbHelper.getProducts();
      applyFilter(_searchQuery);
    } catch (e, stackTrace) {
      _logger.logUi(
        'Failed to refresh products from local cache',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> addOrUpdateProductLocal(Product product) async {
    await LocalDbHelper.addOrUpdateProduct(product);
    final index = _allProducts.indexWhere((p) => p.productId == product.productId);
    if (index >= 0) {
      _allProducts[index] = product;
    } else {
      _allProducts.insert(0, product);
    }
    applyFilter(_searchQuery);
  }

  Future<void> deleteProductLocal(String productId) async {
    await LocalDbHelper.deleteProduct(productId);
    _allProducts.removeWhere((p) => p.productId == productId);
    applyFilter(_searchQuery);
  }

  void applyFilter(String query) {
    _searchQuery = query.toLowerCase();

    // ✅ ADDED: Filter log
    _logger.logUi(
      'Applying product filter | Query: "$query"',
      level: LogLevel.debug,
    );

    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = _allProducts
          .where(
            (product) => product.productName.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }

    // ✅ ADDED: Filter result log
    _logger.logUi(
      'Filtered products count: ${_filteredProducts.length}',
      level: LogLevel.debug,
    );

    notifyListeners();
  }
}
