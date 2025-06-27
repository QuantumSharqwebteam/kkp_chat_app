import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/models/product_model.dart';

class ProductsBottomSheet extends StatelessWidget {
  final Future<List<Product>> productsFuture;
  final Function(Product) onProductTap;

  const ProductsBottomSheet({
    super.key,
    required this.productsFuture,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading products"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No products available"));
        } else {
          final products = snapshot.data!;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            height: MediaQuery.of(context).size.height * 0.6,
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductListItem(context, product);
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildProductListItem(BuildContext context, Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 0,
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                product.imageUrl,
                height: 60,
                width: 65,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error);
                },
              ),
            ),
            const SizedBox(width: 4),
            Text(
              product.productName,
              style: AppTextStyles.black12_700,
            ),
          ],
        ),
        trailing: const Icon(
          Icons.ios_share_rounded,
          color: AppColors.blue0056FB,
        ),
        onTap: () {
          onProductTap(product);
          Navigator.pop(context);
        },
      ),
    );
  }
}
