import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/models/product_model.dart';
import 'package:kkp_chat_app/data/repositories/product_repository.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_search_field.dart';
import 'package:kkp_chat_app/presentation/common_widgets/shimmer_grid.dart';
import 'package:kkp_chat_app/presentation/customer/screen/customer_product_description_page.dart';
import 'package:kkp_chat_app/presentation/common_widgets/products/product_item.dart';

class CustomerProductsPage extends StatefulWidget {
  const CustomerProductsPage({super.key});

  @override
  State<CustomerProductsPage> createState() => _CustomerProductsPageState();
}

class _CustomerProductsPageState extends State<CustomerProductsPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: Text('Product', style: AppTextStyles.black18_600),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(
                    context, CustomerRoutes.customerNotification);
              },
              icon: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: Utils().width(context),
            color: AppColors.background,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: CustomSearchBar(
              width: Utils().width(context),
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
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 20),
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
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
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
