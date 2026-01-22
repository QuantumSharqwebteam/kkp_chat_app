import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';

import 'package:kkpchatapp/logic/agent/marketing_product_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/products/product_item.dart';

import 'package:kkpchatapp/presentation/common_widgets/shimmer_grid.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

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
    final locale = AppLocalizations.of(context)!;
    final provider = context.watch<MarketingProductProvider>();
    return Scaffold(
      appBar: _buildAppBar(context, provider),
      body: Padding(
        padding: const EdgeInsets.only(left: 14, right: 14),
        child: RefreshIndicator(
          // ✅ Pull-to-refresh action
          onRefresh: () async {
            await context
                .read<MarketingProductProvider>()
                .fetchProducts(isRefresh: true); // ✅ show app bar loader
          },

          // ✅ RefreshIndicator NEEDS a scrollable child
          child: provider.isLoading
              ? const Center(child: ShimmerGrid())

              // ✅ EMPTY STATE STILL SCROLLABLE
              : provider.filteredProducts.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      shrinkWrap: true, // IMPORTANT
                      children: [
                        SizedBox(height: Utils().height(context) * 0.3),
                        Center(
                          child: Text(
                            provider.searchQuery.isEmpty
                                ? locale.noProductsAvailable
                                : locale.noMatchingProducts,
                          ),
                        ),
                      ],
                    )

                  // ✅ PRODUCT GRID
                  : _buildProductsList(context, provider.filteredProducts),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, MarketingProductProvider provider) {
    final locale = AppLocalizations.of(context)!;

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
              Text(locale.product, style: AppTextStyles.black20_600),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, MarketingRoutes.marketingNotifications);
                },
                icon: const Icon(Icons.notifications_active_outlined),
                iconSize: 25,
              ),
              // IconButton(
              //   icon: const Icon(Icons.refresh),
              //   onPressed: provider.isRefreshing
              //       ? null
              //       : () {
              //           context.read<MarketingProductProvider>().fetchProducts(isRefresh: true);
              //         },
              // ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          CustomSearchBar(
            width: double.infinity,
            enable: true,
            controller: _searchController,
            hintText: AppLocalizations.of(context)!.searchProducts,
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
    final screenHeight = Utils().height(context);
    final screenWidth = Utils().width(context);
    final isTablet = screenWidth >= 600;
    final isLandscape = screenWidth > screenHeight;

    // Adaptive height logic to prevent overflow
    double itemHeight;
    if (isTablet) {
      itemHeight = isLandscape ? screenHeight * 0.33 : screenHeight * 0.28;
    } else {
      itemHeight = screenHeight * 0.24;
    }

    return ResponsiveGridList(
      horizontalGridSpacing: screenWidth * 0.025,
      verticalGridSpacing: screenHeight * 0.0125,
      horizontalGridMargin: screenWidth * 0.01,
      verticalGridMargin: screenHeight * 0.025,
      minItemWidth: screenWidth * 0.42,
      maxItemsPerRow: 4,
      listViewBuilderOptions: ListViewBuilderOptions(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
      ),
      children: products.map((product) {
        return SizedBox(
          height: itemHeight,
          child: ProductItem(
            product: product,
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                MarketingRoutes.marketingProductDescription,
                arguments: product,
              );
              if (result == true && context.mounted) {
                context.read<MarketingProductProvider>().fetchProducts();
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return SizedBox(
      height: 95,
      width: 88,
      child: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            MarketingRoutes.addProductScreen,
          );
          if (result == true && context.mounted) {
            context.read<MarketingProductProvider>().fetchProducts();
          }
        },
        backgroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        tooltip: locale.uploadNewProduct,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload, size: 36, color: AppColors.grey7B7B7B),
            //SizedBox(height: 6),
            Text(
              locale.uploadHere,
              textAlign: TextAlign.center,
              style: AppTextStyles.black10_600,
            ),
          ],
        ),
      ),
    );
  }
}
