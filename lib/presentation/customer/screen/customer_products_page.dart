import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';

import 'package:kkpchatapp/logic/customer/customer_product_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_grid.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_product_description_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/products/product_item.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

class CustomerProductsPage extends StatefulWidget {
  const CustomerProductsPage({super.key});

  @override
  State<CustomerProductsPage> createState() => _CustomerProductsPageState();
}

class _CustomerProductsPageState extends State<CustomerProductsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final productProvider = Provider.of<CustomerProductProvider>(context, listen: false);
      productProvider.filterProducts(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Handle manual refresh
  Future<void> _refreshProducts() async {
    await Provider.of<CustomerProductProvider>(context, listen: false).refreshProducts();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<CustomerProductProvider>(context);
    final utils = Utils();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: Text(AppLocalizations.of(context)!.product, style: AppTextStyles.black18_600),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, CustomerRoutes.customerNotification);
            },
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.black,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: utils.width(context),
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: CustomSearchBar(
              width: utils.width(context),
              enable: true,
              controller: _searchController,
              hintText: AppLocalizations.of(context)!.searchHere,
            ),
          ),
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: ShimmerGrid())
                : productProvider.error != null
                    ? Center(child: Text(productProvider.error!))
                    : productProvider.filteredProducts.isEmpty
                        ? Center(child: Text(AppLocalizations.of(context)!.noProductsAvailable))
                        : RefreshIndicator(
                            onRefresh: _refreshProducts,
                            child: ResponsiveGridList(
                              minItemWidth: utils.width(context) * 0.4,
                              maxItemsPerRow: 4,
                              horizontalGridSpacing: utils.width(context) * 0.025,
                              verticalGridSpacing: utils.height(context) * 0.0125,
                              horizontalGridMargin: utils.width(context) * 0.025,
                              verticalGridMargin: utils.height(context) * 0.025,
                              listViewBuilderOptions: ListViewBuilderOptions(
                                physics: const BouncingScrollPhysics(),
                              ),
                              children: productProvider.filteredProducts.map((product) {
                                return ProductItem(
                                  product: product,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CustomerProductDescriptionPage(product: product),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
