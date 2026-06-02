class Product {
  final String imageUrl;
  final List<ProductColor> colors;
  final int stock;
  final List<String> sizes;
  final double price;
  final String? productId;
  final String productName;
  final String? description;

  Product({
    required this.imageUrl,
    required this.colors,
    required this.stock,
    required this.sizes,
    required this.price,
    this.productId,
    required this.productName,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final colorsJson = json['colors'];
    final sizesJson = json['sizes'];
    final priceJson = json['price'];
    final imageUrlValue = json['imageUrl'];
    final productNameValue = json['productName'];

    return Product(
      imageUrl: imageUrlValue?.toString() ?? '',
      colors: (colorsJson is Iterable)
          ? colorsJson
              .whereType<Map>()
              .map((colorMap) => ProductColor.fromJson(Map<String, dynamic>.from(colorMap)))
              .toList()
          : [],
      stock: json['stock'] is num ? (json['stock'] as num).toInt() : int.tryParse('${json['stock']}') ?? 0,
      sizes: (sizesJson is Iterable) ? sizesJson.map((e) => e.toString()).toList() : [],
      price: priceJson is num
          ? priceJson.toDouble()
          : double.tryParse('$priceJson') ?? 0.0,
      productId: json['productId'] ?? json['_id'],
      productName: productNameValue?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  /// For local persistence/cache (keeps stable identifiers).
  Map<String, dynamic> toJson() {
    return {
      "productId": productId,
      "productName": productName,
      "imageUrl": imageUrl,
      "colors": colors.map((c) => c.toJson()).toList(),
      "sizes": sizes,
      "stock": stock,
      "price": price,
      "description": description,
    };
  }

  /// ✅ FOR ADD PRODUCT (NO productId)
  Map<String, dynamic> toCreateJson() {
    return {
      "productName": productName,
      "imageUrl": imageUrl,
      "colors": colors.map((c) => c.toJson()).toList(),
      "sizes": sizes,
      "stock": stock,
      "price": price,
      "description": description,
    };
  }

  /// ✅ FOR UPDATE PRODUCT (NO productId in body)
  Map<String, dynamic> toUpdateJson() {
    return {
      "productName": productName,
      "imageUrl": imageUrl,
      "colors": colors.map((c) => c.toJson()).toList(),
      "sizes": sizes,
      "stock": stock,
      "price": price,
      "description": description,
    };
  }
}

class ProductColor {
  final String colorName;
  final String colorCode;

  ProductColor({
    required this.colorName,
    required this.colorCode,
  });

  factory ProductColor.fromJson(Map<String, dynamic> json) {
    return ProductColor(
      colorName: json['colorName']?.toString() ?? '',
      colorCode: json['colorCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "colorName": colorName,
      "colorCode": colorCode,
    };
  }
}
