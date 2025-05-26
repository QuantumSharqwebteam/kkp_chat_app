import 'package:flutter_test/flutter_test.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'fake_product_provider.dart';
import 'fake_product_repository.dart';

void main() {
  late FakeProductRepository fakeRepo;
  late FakeMarketingProductProvider provider;

  final productList = [
    Product(
        productName: "Shoes",
        price: 49.99,
        stock: 10,
        sizes: [],
        colors: [],
        imageUrl: "",
        description: ""),
    Product(
        productName: "Shirt",
        price: 19.99,
        stock: 20,
        sizes: [],
        colors: [],
        imageUrl: "",
        description: ""),
    Product(
        productName: "Shorts",
        price: 29.99,
        stock: 15,
        sizes: [],
        colors: [],
        imageUrl: "",
        description: ""),
  ];

  setUp(() {
    fakeRepo = FakeProductRepository();
    fakeRepo.mockProducts = productList;

    provider = FakeMarketingProductProvider(fakeRepo);
  });

  test('should fetch all products and populate filtered list', () async {
    await provider.fetchProducts();
    expect(provider.filteredProducts.length, 3);
    expect(provider.isLoading, false);
  });

  test('should apply search filter correctly', () async {
    await provider.fetchProducts();
    provider.applyFilter('shirt'); // match only one
    expect(provider.filteredProducts.length, 1);
    expect(provider.filteredProducts.first.productName.toLowerCase(),
        contains('shirt'));
  });

  test('should show all products when search query is empty', () async {
    await provider.fetchProducts();
    provider.applyFilter('');
    expect(provider.filteredProducts.length, 3);
  });

  test('should handle error and empty lists on fetch failure', () async {
    fakeRepo.shouldThrow = true;
    await provider.fetchProducts();
    expect(provider.filteredProducts.length, 0);
    expect(provider.isLoading, false);
  });
}
