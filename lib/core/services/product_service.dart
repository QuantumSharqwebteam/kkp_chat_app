import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/data/models/product_model.dart';

class ProductService {
  final String _baseUrl = "${dotenv.env["BASE_URL"]}/product";

  final http.Client client;

  ProductService({http.Client? client}) : client = client ?? http.Client();

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await client.get(Uri.parse("$_baseUrl/getAll"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['message'];

        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load products");
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }

  // Delete product API
  Future<bool> deleteProduct(String productId) async {
    try {
      final response = await client.delete(
        Uri.parse("$_baseUrl/delete/$productId"),
      );

      if (response.statusCode == 200) {
        return true; // Success
      } else {
        return false; // Failure
      }
    } catch (e) {
      throw Exception("Error deleting product: $e");
    }
  }

  // Add product API
  Future<bool> addProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/add"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(product.toJson()), // Convert product to JSON
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true; // Success
      } else {
        return false; // Failure
      }
    } catch (e) {
      throw Exception("Error adding product: $e");
    }
  }

  Future<bool> updateProduct(
      String productId, Map<String, dynamic> updatedData) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/update/$productId"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        return true; // Success
      } else {
        return false; // Failure
      }
    } catch (e) {
      throw Exception("Error updating product: $e");
    }
  }
}
