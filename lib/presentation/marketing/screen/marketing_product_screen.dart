import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';

import 'package:kkpchatapp/logic/agent/marketing_product_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/products/product_item.dart';

import 'package:kkpchatapp/presentation/common_widgets/shimmer_grid.dart';
import 'package:provider/provider.dart';

import '../../../data/models/product_model.dart';

class MarketingProductScreen extends StatefulWidget {
  const MarketingProductScreen({super.key});

  @override
  State<MarketingProductScreen> createState() => _MarketingProductScreenState();
}

class _MarketingProductScreenState extends State<MarketingProductScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<MarketingProductProvider>();
    _searchController.text = provider.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketingProductProvider>();

    return Scaffold(
      appBar: _buildAppBar(context, provider),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: provider.isLoading
            ? const Center(child: ShimmerGrid())
            : provider.filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      provider.searchQuery.isEmpty
                          ? "No products available"
                          : "No matching products found",
                    ),
                  )
                : _buildProductsList(context, provider.filteredProducts),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, MarketingProductProvider provider) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: MediaQuery.of(context).size.height * 0.14,
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
                icon: const Icon(Icons.notifications_active_outlined),
                iconSize: 25,
              ),
            ],
          ),
          CustomSearchBar(
            width: double.infinity,
            enable: true,
            controller: _searchController,
            hintText: "Search products...",
            onChanged: (query) {
              provider.applyFilter(query);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        maxCrossAxisExtent: 250,
        mainAxisExtent: 250,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductItem(
          product: product,
          onTap: () async {
            final result = await Navigator.pushNamed(
              context,
              MarketingRoutes.marketingProductDescription,
              arguments: product,
            );

            if (result == true) {
              // refresh product list
              if (context.mounted) {
                context.read<MarketingProductProvider>().fetchProducts();
              }
            }
          },
        );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return SizedBox(
      height: 110,
      width: 110,
      child: FloatingActionButton(
        elevation: 10,
        tooltip: "Upload new product here",
        onPressed: () async {
          final result = await Navigator.pushNamed(
              context, MarketingRoutes.addProductScreen);
          if (result == true) {
            if (context.mounted) {
              context.read<MarketingProductProvider>().fetchProducts();
            }
          }
        },
        backgroundColor: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            Icon(Icons.cloud_upload, size: 80, color: AppColors.grey7B7B7B),
            Text("Upload Product", style: AppTextStyles.black10_600),
          ],
        ),
      ),
    );
  }
}
