class Product {
  final String imageUrl;
  final List<ProductColor> colors;
  final int stock;
  final List<String> sizes;
  final double price;
  final String productId;
  final String productName;
  final String? description;

  Product({
    required this.imageUrl,
    required this.colors,
    required this.stock,
    required this.sizes,
    required this.price,
    required this.productId,
    required this.productName,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      imageUrl: json['imageUrl'],
      colors: (json['colors'] as List)
          .map((color) => ProductColor.fromJson(color))
          .toList(),
      stock: json['stock'],
      sizes: List<String>.from(json['sizes']),
      price: (json['price'] as num).toDouble(),
      productId: json['productId'],
      productName: json['productName'],
      description: json['description'],
    );
  }

  // Convert Product object to JSON
  Map<String, dynamic> toJson() {
    return {
      "productName": productName,
      "imageUrl": imageUrl,
      "colors": colors.map((color) => color.toJson()).toList(),
      "sizes": sizes,
      "stock": stock,
      "price": price,
      "description": description
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
      colorName: json['colorName'],
      colorCode: json['colorCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "colorName": colorName,
      "colorCode": colorCode,
    };
  }
}
