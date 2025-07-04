import 'package:kkpchatapp/data/models/product_model.dart';

class FakeProductRepository {
  List<Product> mockProducts = [];
  bool shouldThrow = false;

  Future<List<Product>> getProducts() async {
    if (shouldThrow) throw Exception("Failed to fetch");
    return mockProducts;
  }
}
