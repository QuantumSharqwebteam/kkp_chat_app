import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/poster_model.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/data/repositories/poster_repository.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_chat_screen.dart';

class CustomerHomeProvider with ChangeNotifier {
  final ProductRepository _productRepository = ProductRepository();
  final AuthRepository _authRepository = AuthRepository();
  final PosterRepository _posterRepository = PosterRepository();
  final SocketService _socketService;
  final GlobalKey<NavigatorState> navigatorKey;

  CustomerHomeProvider(this._socketService, this.navigatorKey);

  Profile? _profileData;
  Profile? get profileData => _profileData;

  List<Product>? _products;
  List<Product>? get products => _products;

  List<Product>? _newProducts;
  List<Product>? get newProducts => _newProducts;

  List<Product>? _previousProducts;
  List<Product>? get previousProducts => _previousProducts;

  int _notificationCount = 0;
  int get notificationCount => _notificationCount;

  String? _name;
  String? get name => _name;

  String? _customerEmail;
  String? get customerEmail => _customerEmail;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  List<PosterModel>? _posters;
  List<PosterModel>? get posters => _posters;

  // ✅ Added: Getter for fallback + fetched carousel images
  List<String> get carouselImageUrls {
    if (_posters == null) {
      return []; // indicates loading
    }

    final fallback = "assets/images/carousel_image1.png";
    final urls = _posters!
        .map((poster) => _normalizePosterUrl(poster.mediaUrl))
        .where((url) => url.isNotEmpty)
        .map((url) => _isValidPosterUrl(url) ? url : fallback)
        .toList();

    if (urls.isEmpty) {
      return List.filled(3, fallback);
    }

    return urls;
  }

  String _normalizePosterUrl(String? url) {
    return url?.trim() ?? '';
  }

  bool _isValidPosterUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
  }

  // ✅ Optional: Flag to indicate poster loading
  bool get isPostersLoading => _posters == null;

  Future<void> fetchPosters() async {
    try {
      _posters = await _posterRepository.getPosters();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  Future<void> loadUserInfo() async {
    try {
      final Map<String, dynamic> userData = await _authRepository.getUserInfo();
      _profileData = Profile.fromJson(userData['message']);
      _name = _profileData?.name;
      _customerEmail = _profileData?.email;
      final box = await Hive.openBox('profileBox');
      box.put('profile', _profileData!.toJson());
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final productsData = await _productRepository.getProducts();
      await LocalDbHelper.saveProducts(productsData);
      _products = productsData;
      _rebuildProductSections();
      // ✅ Preload product images to improve perceived load time
      for (var product in _products!) {
        final image = CachedNetworkImageProvider(product.imageUrl);
        final ctx = navigatorKey.currentState?.context;
        if (ctx != null && ctx.mounted) {
          precacheImage(image, ctx);
        }
      }
      notifyListeners();
    } catch (e) {
      try {
        _products = await LocalDbHelper.getProducts();
        _rebuildProductSections();
      } catch (_) {}
      if (kDebugMode) {
        print(e.toString());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProductsFromHive() async {
    try {
      _products = await LocalDbHelper.getProducts();
      _rebuildProductSections();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to refresh customer home products from local cache: $e');
      }
    }
  }

  Future<void> addOrUpdateProductLocal(Product product) async {
    await LocalDbHelper.addOrUpdateProduct(product);
    _products ??= [];
    final index =
        _products!.indexWhere((p) => p.productId == product.productId);
    if (index >= 0) {
      _products![index] = product;
    } else {
      _products!.insert(0, product);
    }
    _rebuildProductSections();
    notifyListeners();
  }

  Future<void> deleteProductLocal(String productId) async {
    await LocalDbHelper.deleteProduct(productId);
    _products ??= [];
    _products!.removeWhere((p) => p.productId == productId);
    _rebuildProductSections();
    notifyListeners();
  }

  void _rebuildProductSections() {
    final all = _products ?? <Product>[];
    if (all.isEmpty) {
      _newProducts = [];
      _previousProducts = [];
      return;
    }

    final recentCount = all.length >= 2 ? 2 : all.length;
    _newProducts = all.sublist(0, recentCount);
    _previousProducts = all.length >= 3 ? all.sublist(recentCount) : [];
  }

  Future<void> fetchNotificationCount() async {
    final currentUserEmail = _profileData?.email;
    if (currentUserEmail != null) {
      final boxNameWithCount = '${currentUserEmail}count';
      final box = await Hive.openBox<int>(boxNameWithCount);
      _notificationCount = box.get('count', defaultValue: 0) ?? 0;
      notifyListeners();
      debugPrint("Fetched notification count: $_notificationCount");
    }
  }

  Future<void> resetMessageCount() async {
    final email = _profileData?.email;
    final boxNameWithCount = '${email}count';
    final box = await Hive.openBox<int>(boxNameWithCount);
    await box.put('count', 0);
    _notificationCount = 0;
    notifyListeners();
  }

  void initSocketService() {
    _socketService.onMessageReceived((data) {}, refreshCallback: () {
      fetchNotificationCount();
    });
  }

  void navigateToChat() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => CustomerChatScreen(
          agentName: "Agent",
          customerName: _name,
          customerEmail: _customerEmail,
          navigatorKey: navigatorKey,
        ),
      ),
    );
  }

  Future<void> updateCustomerProfile({
    required String name,
    required String number,
    required String customerType,
    required String gstNo,
    required String panNo,
  }) async {
    try {
      await _authRepository.updateUserDetails(
        name: name,
        number: number,
        customerType: customerType,
        gstNo: gstNo,
        panNo: panNo,
      );

      await loadUserInfo(); // refresh profile data after update
    } catch (e) {
      if (kDebugMode) {
        print("Failed to update profile: $e");
      }
      rethrow;
    }
  }
}
