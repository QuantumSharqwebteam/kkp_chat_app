import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/data/models/product_model.dart';
import 'package:kkp_chat_app/data/models/profile_model.dart';
import 'package:kkp_chat_app/data/repositories/auth_repository.dart';
import 'package:kkp_chat_app/data/repositories/product_repository.dart';
import 'package:kkp_chat_app/presentation/common_widgets/shimmer_grid.dart';
import 'package:kkp_chat_app/presentation/customer/screen/customer_chat_screen.dart';
import 'package:kkp_chat_app/presentation/customer/screen/customer_product_description_page.dart';
import 'package:kkp_chat_app/presentation/customer/widget/custom_app_bar.dart';
import 'package:kkp_chat_app/presentation/common_widgets/products/product_item.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final ProductRepository _productRepository = ProductRepository();
  late Future<List<Product>> _productsFuture;
  AuthRepository auth = AuthRepository();
  Profile? profileData;
  String? name;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productRepository.getProducts();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      profileData = await auth.getUserInfo();
      if (mounted) {
        setState(() {
          name = profileData?.name;
          profileImageUrl = profileData!.profileUrl;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        if (mounted) {
          print(e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 100),
        child: SafeArea(
            child: CustomAppBar(
          name: name,
          url: profileImageUrl,
        )),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _carousel(),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _enquirySupport(onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return CustomerChatScreen(
                          agentName: "Agent",
                          customerName: name,
                          customerEmail: profileData!.email,
                          customerImage: profileImageUrl,
                        );
                      }));
                    }),
                    const SizedBox(height: 20),

                    //new products list
                    Text('New Products', style: AppTextStyles.black18_600),

                    FutureBuilder<List<Product>>(
                      future: _productsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ShimmerGrid();
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}"));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text("No products available"));
                        }

                        final products = snapshot.data!;
                        final newProducts = products.length >= 2
                            ? products.sublist(0, 2)
                            : products;
                        final previousProducts = products.length >= 2
                            ? products.sublist(
                                products.length - 2, products.length)
                            : products;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 15),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                mainAxisExtent: 250,
                              ),
                              itemCount: newProducts.length,
                              itemBuilder: (context, index) {
                                final product = newProducts[index];
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
                            ),
                            const SizedBox(height: 20),
                            //previous products lists
                            Text('Previous Products',
                                style: AppTextStyles.black18_600),

                            GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 15),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                mainAxisExtent: 250,
                              ),
                              itemCount: previousProducts.length,
                              itemBuilder: (context, index) {
                                final product = previousProducts[index];
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
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carousel() {
    List<String> imageUrls = [
      "assets/images/carousel_image1.png",
      "assets/images/carousel_image1.png",
      "assets/images/carousel_image1.png",
    ];

    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 6,
        viewportFraction: 1,
      ),
      items: imageUrls.map((imageUrl) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(imageUrl, fit: BoxFit.fill),
        );
      }).toList(),
    );
  }
}

Widget _enquirySupport({VoidCallback? onTap}) {
  return Card(
    color: Colors.white,
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    child: ListTile(
      onTap: onTap,
      leading: Stack(children: [
        const CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage("assets/images/user4.png"),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            elevation: 5,
            color: Colors.transparent,
            type: MaterialType.circle,
            child: Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: AppColors.activeGreen,
              ),
            ),
          ),
        ),
      ]),
      title: Text('Product Enquirers', style: AppTextStyles.black16_600),
      subtitle: Text('How may I Help you?',
          overflow: TextOverflow.ellipsis, style: AppTextStyles.black12_400),
      trailing: Text('2m', style: AppTextStyles.black12_700),
    ),
  );
}
