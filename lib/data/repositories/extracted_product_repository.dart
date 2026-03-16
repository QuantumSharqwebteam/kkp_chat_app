import 'package:kkpchatapp/data/local_storage/product_database.dart';
import 'package:kkpchatapp/data/models/extracted_product_data.dart';

class ExtractedProductRepository {
  final ProductDatabase _database = ProductDatabase();

  /// Insert extracted product data
  Future<ExtractedProductData?> insert(ExtractedProductData data) async {
    try {
      final id = data.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final dataWithId = data.copyWith(id: id);

      await _database.insertExtractedProduct(dataWithId);
      return dataWithId;
    } catch (e) {
      print('Error inserting extracted product data: $e');
      return null;
    }
  }

  /// Get all extracted products for a specific chat
  Future<List<ExtractedProductData>> getByChat(String chatId) async {
    try {
      return await _database.getExtractedProductsByChat(chatId);
    } catch (e) {
      print('Error fetching extracted products by chat: $e');
      return [];
    }
  }

  /// Get all extracted products for an agent
  Future<List<ExtractedProductData>> getByAgent(String agentEmail) async {
    try {
      return await _database.getExtractedProductsByAgent(agentEmail);
    } catch (e) {
      print('Error fetching extracted products by agent: $e');
      return [];
    }
  }

  /// Get extracted products within a date range
  Future<List<ExtractedProductData>> getByDateRange(
    String agentEmail,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _database.getExtractedProductsByDateRange(agentEmail, startDate, endDate);
    } catch (e) {
      print('Error fetching extracted products by date range: $e');
      return [];
    }
  }

  /// Update an extracted product entry
  Future<bool> update(String id, Map<String, dynamic> updates) async {
    try {
      final rowsAffected = await _database.updateExtractedProduct(id, updates);
      return rowsAffected > 0;
    } catch (e) {
      print('Error updating extracted product: $e');
      return false;
    }
  }

  /// Delete an extracted product entry
  Future<bool> delete(String id) async {
    try {
      final rowsAffected = await _database.deleteExtractedProduct(id);
      return rowsAffected > 0;
    } catch (e) {
      print('Error deleting extracted product: $e');
      return false;
    }
  }
}
