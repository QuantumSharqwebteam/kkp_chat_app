import '../../core/services/product_service.dart';
import '../models/product_model.dart';

class ProductRepository {
  final ProductService _productService = ProductService();
  // get all products
  Future<List<Product>> getProducts() async {
    return await _productService.fetchProducts();
  }

  // Delete a product
  Future<bool> deleteProduct(String productId) async {
    return await _productService.deleteProduct(productId);
  }
}
