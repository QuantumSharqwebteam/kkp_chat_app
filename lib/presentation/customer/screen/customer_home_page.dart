import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/logic/customer/customer_home_provider.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_product_description_page.dart';
import 'package:provider/provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_grid.dart';
import 'package:kkpchatapp/presentation/customer/widget/custom_app_bar.dart';
import 'package:kkpchatapp/presentation/common_widgets/products/product_item.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  late CustomerHomeProvider _provider;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = Provider.of<CustomerHomeProvider>(context);
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _provider.loadUserInfo();
        _provider.fetchProducts();
        _provider.initSocketService();
      });
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 100),
        child: SafeArea(
          child: CustomAppBar(
            name: _provider.profileData?.name,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _provider.fetchNotificationCount,
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
                      _enquirySupport(
                        onTap: () async {
                          await _provider.resetMessageCount();
                          await _provider.fetchNotificationCount();
                          _provider.navigateToChat();
                        },
                        notificationCount: _provider.notificationCount,
                      ),
                      const SizedBox(height: 20),
                      Text('New Products',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      _provider.isLoading
                          ? ShimmerGrid()
                          : _provider.newProducts != null &&
                                  _provider.previousProducts != null
                              ? Column(
                                  children: [
                                    GridView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 15),
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        mainAxisExtent: 250,
                                      ),
                                      itemCount: _provider.newProducts!.length,
                                      itemBuilder: (context, index) {
                                        final product =
                                            _provider.newProducts![index];
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
                                    Text('Previous Products',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    GridView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 15),
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        mainAxisExtent: 250,
                                      ),
                                      itemCount:
                                          _provider.previousProducts!.length,
                                      itemBuilder: (context, index) {
                                        final product =
                                            _provider.previousProducts![index];
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
                                )
                              : Center(child: Text("No products available")),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _enquirySupport({VoidCallback? onTap, int? notificationCount}) {
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
          // Positioned(
          //   bottom: 0,
          //   right: 0,
          //   child: Material(
          //     elevation: 5,
          //     color: Colors.transparent,
          //     type: MaterialType.circle,
          //     child: Container(
          //       height: 12,
          //       width: 12,
          //       decoration: BoxDecoration(
          //         borderRadius: BorderRadius.circular(50),
          //         color: Colors.green,
          //       ),
          //     ),
          //   ),
          // ),
        ]),
        title: Text('Product Enquirers',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text('How may I Help you?', style: TextStyle(fontSize: 12)),
        trailing: notificationCount != null && notificationCount > 0
            ? Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  notificationCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              )
            : SizedBox.shrink(),
      ),
    );
  }
}
