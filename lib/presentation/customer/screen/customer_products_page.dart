import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_grid.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_product_description_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/products/product_item.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

class CustomerProductsPage extends StatefulWidget {
  const CustomerProductsPage({super.key});

  @override
  State<CustomerProductsPage> createState() => _CustomerProductsPageState();
}

class _CustomerProductsPageState extends State<CustomerProductsPage> {
  final ProductRepository _productRepository = ProductRepository();
  List<Product> _allProducts = [];
  late Future<List<Product>> _productsFuture;
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

  @override
  Widget build(BuildContext context) {
    final utils = Utils();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: Text('Product', style: AppTextStyles.black18_600),
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
              hintText: 'Search Here...',
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
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
                    : ResponsiveGridList(
                        minItemWidth: utils.width(context) * 0.4,
                        maxItemsPerRow: 4,
                        horizontalGridSpacing:
                            utils.width(context) * 0.025,
                        verticalGridSpacing:
                            utils.height(context) * 0.0125,
                        horizontalGridMargin:
                            utils.width(context) * 0.025,
                        verticalGridMargin:
                            utils.height(context) * 0.025,
                        listViewBuilderOptions:  ListViewBuilderOptions(
                          physics: BouncingScrollPhysics(),
                        ),
                        children: _filteredProducts.map((product) {
                          return ProductItem(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CustomerProductDescriptionPage(
                                          product: product),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
