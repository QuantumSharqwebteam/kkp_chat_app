import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_chat_screen.dart';

class CustomerHomeProvider with ChangeNotifier {
  final ProductRepository _productRepository = ProductRepository();
  final AuthRepository _authRepository = AuthRepository();
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
      _products = productsData;
      if (_products!.length >= 2) {
        _newProducts = _products!.sublist(0, 2);
        _previousProducts =
            _products!.sublist(_products!.length - 2, _products!.length);
      } else {
        _newProducts = _products;
        _previousProducts = _products;
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNotificationCount() async {
    final currentUserEmail = _profileData?.email;
    if (currentUserEmail != null) {
      final boxNameWithCount = '${currentUserEmail}count';
      final box = await Hive.openBox<int>(boxNameWithCount);
      _notificationCount = box.get('count', defaultValue: 0) ?? 0;
      notifyListeners();
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
    Navigator.push(
      navigatorKey.currentContext!,
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
}
