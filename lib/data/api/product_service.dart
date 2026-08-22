import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/data/api/api_client.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/product_model.dart';

// class ProductService {
//   final String _baseUrl = "${dotenv.env["BASE_URL"]}/product";

//   final http.Client client;

//   ProductService({http.Client? client}) : client = client ?? ApiClient.create();

//   Future<List<Product>> fetchProducts() async {
//     final token = await LocalDbHelper.getToken();
//     try {
//       final response = await client.get(
//         Uri.parse("$_baseUrl/getAll"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<dynamic> productsJson = data['message'];

//         return productsJson.map((json) => Product.fromJson(json)).toList();
//       } else {
//         throw Exception("Failed to load products");
//       }
//     } catch (e) {
//       throw Exception("Error fetching products: $e");
//     }
//   }

//   // Delete product API
//   Future<bool> deleteProduct(String productId) async {
//     final token = await LocalDbHelper.getToken();
//     try {
//       final response = await client.delete(
//         Uri.parse("$_baseUrl/delete/$productId"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       if (response.statusCode == 200) {
//         return true; // Success
//       } else {
//         return false; // Failure
//       }
//     } catch (e) {
//       throw Exception("Error deleting product: $e");
//     }
//   }

//   // Add product API
//   Future<bool> addProduct(Product product) async {
//     final token = await LocalDbHelper.getToken();
//     try {
//       final response = await http.post(
//         Uri.parse("$_baseUrl/add"),
//         headers: {
//           "Content-Type": "application/json",
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(product.toJson()), // Convert product to JSON
//       );

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         return true; // Success
//       } else {
//         return false; // Failure
//       }
//     } catch (e) {
//       throw Exception("Error adding product: $e");
//     }
//   }

//   Future<bool> updateProduct(String productId, Map<String, dynamic> updatedData) async {
//     try {
//       final response = await http.put(
//         Uri.parse("$_baseUrl/update/$productId"),
//         headers: {
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode(updatedData),
//       );

//       if (response.statusCode == 200) {
//         return true; // Success
//       } else {
//         return false; // Failure
//       }
//     } catch (e) {
//       throw Exception("Error updating product: $e");
//     }
//   }
// }

class ProductService {
  final String _baseUrl = "${dotenv.env["BASE_URL"]}/product";
  final http.Client client;

  final LoggingService _logger = LoggingService.instance;

  ProductService({http.Client? client}) : client = client ?? ApiClient.create();

  /// Fetch all products
  Future<List<Product>> fetchProducts() async {
    final token = await LocalDbHelper.getToken();
    final url = Uri.parse("$_baseUrl/getAll");

    _logger.logNetwork(
      'Fetching products',
      level: LogLevel.info,
    );
    _logger.logNetwork(
      'GET $url',
      level: LogLevel.debug,
    );

    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _logger.logNetwork(
        'Response status: ${response.statusCode}',
        level: LogLevel.debug,
      );
      _logger.logNetwork(
        'Raw response body: ${response.body}',
        level: LogLevel.debug,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['message'];

        _logger.logNetwork(
          'Fetched ${productsJson.length} products successfully',
          level: LogLevel.info,
        );

        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        _logger.logNetwork(
          'Failed to fetch products | Status: ${response.statusCode} | Body: ${response.body}',
          level: LogLevel.warning,
        );
        throw Exception("Failed to load products");
      }
    } catch (e, stackTrace) {
      _logger.logNetwork(
        'Exception while fetching products',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception("Error fetching products: $e");
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String productId) async {
    final token = await LocalDbHelper.getToken();
    final url = Uri.parse("$_baseUrl/delete/$productId");

    _logger.logNetwork(
      'Deleting product | ID: $productId',
      level: LogLevel.info,
    );

    try {
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _logger.logNetwork(
        'Delete response status: ${response.statusCode}',
        level: LogLevel.debug,
      );

      if (response.statusCode == 200) {
        _logger.logNetwork(
          'Product deleted successfully | ID: $productId',
          level: LogLevel.info,
        );
        return true;
      } else {
        _logger.logNetwork(
          'Failed to delete product | Status: ${response.statusCode} | Body: ${response.body}',
          level: LogLevel.warning,
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logger.logNetwork(
        'Exception while deleting product | ID: $productId',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception("Error deleting product: $e");
    }
  }

  /// Add product
  Future<bool> addProduct(Product product) async {
    final token = await LocalDbHelper.getToken();
    final url = Uri.parse("$_baseUrl/add");

    _logger.logNetwork(
      'Adding product',
      level: LogLevel.info,
    );
    _logger.logNetwork(
      'POST $url | Payload: ${product.toCreateJson()}',
      level: LogLevel.debug,
    );

    try {
      final response = await client.post(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(product.toCreateJson()),
      );

      _logger.logNetwork(
        'Add product response status: ${response.statusCode}',
        level: LogLevel.debug,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _logger.logNetwork(
          'Product added successfully',
          level: LogLevel.info,
        );
        return true;
      } else {
        _logger.logNetwork(
          'Failed to add product | Status: ${response.statusCode} | Body: ${response.body}',
          level: LogLevel.warning,
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logger.logNetwork(
        'Exception while adding product',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception("Error adding product: $e");
    }
  }

  /// Update product
  Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> updatedData,
  ) async {
    final token = await LocalDbHelper.getToken();
    final url = Uri.parse("$_baseUrl/update/$productId");

    _logger.logNetwork(
      'Updating product | ID: $productId',
      level: LogLevel.info,
    );
    _logger.logNetwork(
      'PUT $url | Payload: $updatedData',
      level: LogLevel.debug,
    );

    try {
      final response = await client.put(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedData),
      );

      _logger.logNetwork(
        'Update response status: ${response.statusCode}',
        level: LogLevel.debug,
      );

      if (response.statusCode == 200) {
        _logger.logNetwork(
          'Product updated successfully | ID: $productId',
          level: LogLevel.info,
        );
        return true;
      } else {
        _logger.logNetwork(
          'Failed to update product | Status: ${response.statusCode} | Body: ${response.body}',
          level: LogLevel.warning,
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logger.logNetwork(
        'Exception while updating product | ID: $productId',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception("Error updating product: $e");
    }
  }
}
