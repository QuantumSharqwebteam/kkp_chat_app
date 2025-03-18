import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_search_field.dart';

import 'package:kkp_chat_app/presentation/common_widgets/shimmer_grid.dart';
import 'package:kkp_chat_app/presentation/customer/widget/product_item.dart';

import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

class MarketingProductScreen extends StatefulWidget {
  const MarketingProductScreen({super.key});

  @override
  State<MarketingProductScreen> createState() => _MarketingProductScreenState();
}

class _MarketingProductScreenState extends State<MarketingProductScreen> {
  final ProductRepository _productRepository = ProductRepository();
  late Future<List<Product>> _productsFuture;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final products = await _productRepository.getProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
    });
    return products;
  }

  void _filterProducts(String query) {
    query = query.toLowerCase();
    setState(() {
      isSearching = query.isNotEmpty;
      _filteredProducts = query.isEmpty
          ? _allProducts
          : _allProducts
              .where((product) =>
                  product.productName.toLowerCase().contains(query))
              .toList();
    });
  }

  void navigateToAddProductScreen() async {
    final result =
        await Navigator.pushNamed(context, MarketingRoutes.addProductScreen);

    if (result == true) {
      setState(() {
        _productsFuture = _fetchProducts(); // Refresh data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.all(14),
        child: _buildProductsList(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: Utils().height(context) * 0.14,
      backgroundColor: AppColors.background,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Product", style: AppTextStyles.black20_600),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                      context, MarketingRoutes.marketingNotifications);
                },
                icon: Icon(Icons.notifications_active_outlined),
                iconSize: 25,
              ),
            ],
          ),
          CustomSearchBar(
            width: double.infinity,
            enable: true,
            controller: _searchController,
            hintText: "Search products...",
            onChanged: _filterProducts,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ShimmerGrid());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No products available"));
        }

        return _filteredProducts.isEmpty
            ? const Center(child: Text("No matching products found"))
            : GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  maxCrossAxisExtent: 250,
                  mainAxisExtent: 250,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ProductItem(
                    product: product,
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        MarketingRoutes.marketingProductDescription,
                        arguments: product,
                      );

                      if (result == true) {
                        setState(() {
                          _productsFuture = _fetchProducts();
                        });
                      }
                    },
                  );
                },
              );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return SizedBox(
      height: 110,
      width: 110,
      child: FloatingActionButton(
        elevation: 10,
        tooltip: "Upload new product here",
        onPressed: navigateToAddProductScreen,
        backgroundColor: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.cloud_upload, size: 80, color: AppColors.grey7B7B7B),
            Text("Upload Product", style: AppTextStyles.black10_600),
          ],
        ),
      ),
    );
  }
}
