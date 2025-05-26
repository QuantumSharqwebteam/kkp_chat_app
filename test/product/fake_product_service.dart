import 'package:kkpchatapp/data/models/product_model.dart';

class FakeProductService {
  bool shouldSucceed = true;
  List<Product> mockProducts = [];
  bool shouldThrow = false;

  Future<bool> addProduct(Product product) async {
    return shouldSucceed;
  }

  Future<bool> updateProduct(
      String productId, Map<String, dynamic> updatedData) async {
    return shouldSucceed;
  }

  Future<List<Product>> getProducts() async {
    if (shouldThrow) throw Exception("Failed to fetch");
    return mockProducts;
  }
}
