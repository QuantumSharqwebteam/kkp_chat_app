import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/connectivity_service.dart';
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
    if (isRefresh) {
      _isRefreshing = true;
      notifyListeners();
    } else {
      // Cache-first: serve Hive data immediately so no shimmer is shown
      try {
        final cached = await LocalDbHelper.getProducts();
        if (cached.isNotEmpty) {
          debugPrint('📦 [ProductProvider] Cache HIT — ${cached.length} products (no shimmer)');
          _allProducts = cached;
          _isLoading = false;
          applyFilter(_searchQuery);
          // Fall through to background API refresh below
        } else {
          debugPrint('📭 [ProductProvider] Cache MISS — showing shimmer');
          _isLoading = true;
          notifyListeners();
        }
      } catch (_) {
        _isLoading = true;
        notifyListeners();
      }
    }

    // Skip network call when offline — cached data is already shown
    if (!ConnectivityService.instance.isOnline) {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    try {
      _logger.logUi('Calling ProductRepository.getProducts()', level: LogLevel.debug);
      _allProducts = await _productRepository.getProducts();
      await LocalDbHelper.saveProducts(_allProducts);
      _logger.logUi('Products fetched | Count: ${_allProducts.length}', level: LogLevel.info);
      applyFilter(_searchQuery);
    } catch (e, stackTrace) {
      _logger.logUi(
        'Error fetching products in MarketingProductProvider',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      // Cache already loaded above; only clear filteredProducts if nothing at all
      if (_allProducts.isEmpty) _filteredProducts = [];
    }

    _isLoading = false;
    _isRefreshing = false;
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
