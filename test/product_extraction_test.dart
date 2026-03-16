import 'package:flutter_test/flutter_test.dart';
import 'package:kkpchatapp/core/services/product_data_extraction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProductDataExtractionService extractionService;

  setUp(() {
    extractionService = ProductDataExtractionService();
  });

  group('Product Data Extraction Service Tests', () {
    test('should extract quantity from message', () async {
      const message = 'I need 100 meters of premium cotton fabric';
      final result = await extractionService.extractProductData(message);

      expect(result, isNotNull);
      expect(result!['quantity'], equals(100));
    });

    test('should extract quality from message', () async {
      const message = 'Looking for premium quality fabric';
      final result = await extractionService.extractProductData(message);

      expect(result, isNotNull);
      expect(result!['quality'], equals('premium'));
    });

    test('should extract weave from message', () async {
      const message = 'Need twill weave cotton';
      final result = await extractionService.extractProductData(message);

      expect(result, isNotNull);
      expect(result!['weave'], equals('twill'));
    });

    test('should extract composition from message', () async {
      const message = 'Composition: 100% cotton';
      final result = await extractionService.extractProductData(message);

      expect(result, isNotNull);
      expect(result!['composition'], equals('100% cotton'));
    });

    test('should extract buyer name from message', () async {
      const message = 'Need 100 meters of premium cotton for customer name: Rahul Sharma';
      final result = await extractionService.extractProductData(message);

      expect(result, isNotNull);
      expect(result!['customerName'], equals('Rahul Sharma'));
    });

    test('should return null for messages without product data', () async {
      const message = 'Hello, how are you?';
      final result = await extractionService.extractProductData(message);

      expect(result, isNull);
    });

    test('should extract multiple fields from complex message', () async {
      const message = 'I need 50 meters of premium twill weave cotton fabric at \$5 per meter';
      final result = await extractionService.extractProductData(message);

      expect(result, isNotNull);
      expect(result!['quantity'], equals(50));
      expect(result!['quality'], equals('premium'));
      expect(result!['weave'], equals('twill'));
      // Note: ML Kit might extract money and date entities if available
    });
  });
}
