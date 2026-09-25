import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/customer/customer_home_provider.dart';
import 'package:kkpchatapp/logic/agent/notification_provider.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_product_description_page.dart';
import 'package:provider/provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_grid.dart';
import 'package:kkpchatapp/presentation/customer/widget/custom_app_bar.dart';
import 'package:kkpchatapp/presentation/common_widgets/products/product_item.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with WidgetsBindingObserver {
  late CustomerHomeProvider _provider;
  late NotificationProvider
      _notificationProvider; // ← FIX: use NotificationProvider for bell badge
  bool _initialized = false;
  int _currentCarouselIndex = 0;

  /// Minimum gap between refreshes triggered by the app coming back to the
  /// foreground.
  ///
  /// `AppLifecycleState.resumed` fires for every brief excursion — the image
  /// picker, a permission dialog, pulling down the notification shade, a
  /// passing phone call, a quick app switch. Refreshing on each one re-hit
  /// getUserInfo and the notifications endpoint every single time. User-driven
  /// refreshes (pull-to-refresh, returning from the notification screen) are
  /// deliberately NOT throttled.
  static const Duration _resumeRefreshInterval = Duration(minutes: 2);

  DateTime? _lastRefreshedAt;

  void _markRefreshed() => _lastRefreshedAt = DateTime.now();

  Future<void> _safeLoadHomeData() async {
    _markRefreshed();
    try {
      await _provider.loadUserInfo();
      await _provider.fetchProducts();
      await _provider.fetchPosters();
      await _provider.fetchNotificationCount();
      _provider.initSocketService();
      // ← FIX: fetch actual notifications so we can count unread ones.
      // Cache-first — main.dart already kicks off a load at startup, so this
      // reuses it rather than issuing a second request.
      await _notificationProvider.ensureLoaded();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CustomerHomePage init load error: $e');
      }
    }
  }

  /// [force] distinguishes a user pulling to refresh (always hits the network)
  /// from the app merely coming back to the foreground (cache-first).
  Future<void> _safeRefresh({bool force = false}) async {
    // Stamped up front, not on completion: two resumes a second apart must not
    // both get through while the first request is still running.
    _markRefreshed();
    try {
      await _provider.loadUserInfo();
      await _provider.fetchNotificationCount();
      // ← FIX: refresh notifications on pull-to-refresh
      await _notificationProvider.ensureLoaded(force: force);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CustomerHomePage refresh error: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;

    final last = _lastRefreshedAt;
    if (last != null &&
        DateTime.now().difference(last) < _resumeRefreshInterval) {
      // Refreshed recently — a short trip out of the app is not a reason to
      // re-hit the API.
      return;
    }

    // Routed through _safeRefresh so a failure is caught: the three calls used
    // to be fired bare here, so any throw became an unhandled async error.
    unawaited(_safeRefresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = Provider.of<CustomerHomeProvider>(context);
    // ← FIX: listen to NotificationProvider for unread count updates
    _notificationProvider = Provider.of<NotificationProvider>(context);
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _safeLoadHomeData();
      });
      _initialized = true;
    }
  }

  // ← FIX: count notifications where viewed == false
  int get _unreadNotificationCount {
    return _notificationProvider.notifications
        .where((n) => !(n.viewed ?? false))
        .length;
  }

  void _onNotificationTap() {
    Navigator.pushNamed(context, CustomerRoutes.customerNotification).then((_) {
      if (!mounted) return;
      // ← FIX: refresh both counts when coming back from notification screen.
      // Stamped as a refresh so the resume that follows (if the user left the
      // app from the notification screen) does not immediately refetch.
      _markRefreshed();
      // Local Hive read, always cheap.
      unawaited(_provider.fetchNotificationCount());
      // Cache-first: markAsRead/markAllRead already updated the shared list in
      // place, so the badge is correct without another round trip.
      unawaited(_notificationProvider.ensureLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final isTablet = Utils().width(context) >= 600;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 100),
        child: SafeArea(
          child: CustomAppBar(
            name: _provider.profileData?.name,
            profileUrl: _provider.profileData?.profileUrl,
            // ← FIX: use unread notification count from NotificationProvider
            notificationCount: _unreadNotificationCount,
            onNotificationTap: _onNotificationTap,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _safeRefresh(force: true),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _carousel(),
                const SizedBox(height: 10),
                _buildCarouselIndicator(),
                const SizedBox(height: 10),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
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
                      SizedBox(height: 20),
                      _provider.isLoading
                          ? ShimmerGrid()
                          : (_provider.newProducts?.isNotEmpty ?? false)
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.newProducts,
                                      style: AppTextStyles.black16_500,
                                    ),
                                    ResponsiveGridList(
                                      horizontalGridSpacing:
                                          Utils().width(context) * 0.025,
                                      verticalGridSpacing:
                                          Utils().height(context) * 0.0125,
                                      horizontalGridMargin:
                                          Utils().width(context) * 0.025,
                                      verticalGridMargin:
                                          Utils().height(context) * 0.015,
                                      minItemWidth: isTablet
                                          ? (isLandscape ? 420 : 340)
                                          : 200,
                                      minItemsPerRow: isLandscape ? 1 : 2,
                                      maxItemsPerRow: isLandscape ? 2 : 2,
                                      listViewBuilderOptions:
                                          ListViewBuilderOptions(
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                      ),
                                      children:
                                          _provider.newProducts!.map((product) {
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
                                    ),
                                    if ((_provider.products?.length ?? 0) >=
                                            3 &&
                                        (_provider
                                                .previousProducts?.isNotEmpty ??
                                            false)) ...[
                                      const SizedBox(height: 20),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .previousProducts,
                                        style: AppTextStyles.black16_500,
                                      ),
                                      ResponsiveGridList(
                                        horizontalGridSpacing:
                                            Utils().width(context) * 0.025,
                                        verticalGridSpacing:
                                            Utils().height(context) * 0.0125,
                                        horizontalGridMargin:
                                            Utils().width(context) * 0.025,
                                        verticalGridMargin:
                                            Utils().height(context) * 0.015,
                                        minItemWidth: isTablet
                                            ? (isLandscape ? 420 : 340)
                                            : 200,
                                        minItemsPerRow: isLandscape ? 1 : 2,
                                        maxItemsPerRow: isLandscape ? 2 : 2,
                                        listViewBuilderOptions:
                                            ListViewBuilderOptions(
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                        ),
                                        children: _provider.previousProducts!
                                            .map((product) {
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
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ],
                                )
                              : Center(child: SizedBox.shrink()),
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
    final imageUrls = _provider.carouselImageUrls;

    final double carouselHeight = MediaQuery.of(context).size.width / (16 / 6);
    final BorderRadius borderRadius = BorderRadius.circular(10);

    // Show shimmer while loading
    if (_provider.isPostersLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SizedBox(
          height: carouselHeight,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SizedBox(
        height: carouselHeight,
        width: double.infinity,
        child: CarouselSlider(
          options: CarouselOptions(
            autoPlay: true,
            enlargeCenterPage: true,
            height: carouselHeight,
            viewportFraction: 1,
            onPageChanged: (index, reason) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
          ),
          items: imageUrls.map((imageUrl) {
            return ClipRRect(
              borderRadius: borderRadius,
              child: imageUrl.startsWith("http")
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                      ),
                    )
                  : Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCarouselIndicator() {
    final imageUrls = _provider.carouselImageUrls;

    return imageUrls.isEmpty
        ? const SizedBox.shrink()
        : AnimatedSmoothIndicator(
            activeIndex: _currentCarouselIndex,
            count: imageUrls.length,
            effect: WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: AppColors.bluePrimary,
              dotColor: Colors.grey,
            ),
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
            backgroundImage: AssetImage("assets/images/user.jpg"),
          ),
        ]),
        title: Text(AppLocalizations.of(context)!.productEnquirers,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(AppLocalizations.of(context)!.howMayIHelpYou,
            style: TextStyle(fontSize: 12)),
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
