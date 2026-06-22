import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kkpchatapp/core/services/call_kit_service.dart';
import 'package:kkpchatapp/core/services/connectivity_service.dart';
import 'package:kkpchatapp/data/api/auth_service.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/logic/agent/group_provider.dart';
import 'package:kkpchatapp/logic/agent/marketing_product_provider.dart';
import 'package:kkpchatapp/logic/agent/agent_home_screen_provider.dart';
import 'package:kkpchatapp/logic/agent/inquiry_provider.dart';
import 'package:kkpchatapp/logic/app_state_provider.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/admin/screens/admin_home.dart';
import 'package:kkpchatapp/presentation/admin/screens/admin_profile_page.dart';
import 'package:kkpchatapp/presentation/admin/screens/customer_inquries.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_home_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/feeds_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/marketing_product_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/profile_screen.dart';
import 'package:kkpchatapp/presentation/marketing/widget/marketing_nav_bar.dart';
import 'package:kkpchatapp/presentation/common_widgets/back_press_handler.dart';
import 'package:provider/provider.dart';

class MarketingHost extends StatefulWidget {
  const MarketingHost({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<MarketingHost> createState() => _MarketingHostState();
}

class _MarketingHostState extends State<MarketingHost>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String? role;
  String? rolename;
  String? agentEmail;
  String? agentName;
  List<Widget> _screens = [];
  late final SocketService _socketService;
  final chatRepository = ChatRepository();
  AuthApi auth = AuthApi();
  StreamSubscription<bool>? _connectivitySub;

  String? _activeIncomingCallId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socketService = SocketService(widget.navigatorKey);
    _loadUserDataAndInitializeSocket().then((_) {
      _initializeNotificationService().then((_) {});
    });
    _connectivitySub = ConnectivityService.instance.onConnectivityChanged.listen((isOnline) {
      if (isOnline) _onInternetRestored();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes if needed
  }

  void initCheck() async {
    // Set the global flag to true after initialization
    isAppInitialized = true;
    try {
      // Also notify provider that app is ready (if provider exists)
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      provider.setAppReady(true);
    } catch (_) {
      // Provider may not exist in some contexts; ignore
    }
  }

  Future<void> _initializeNotificationService() async {
    await NotificationService.init(context, widget.navigatorKey);
    // Mark app initialized after notification service and navigator are ready
    isAppInitialized = true;
  }

  Future<void> _loadUserDataAndInitializeSocket() async {
    final token = await LocalDbHelper.getToken();
    await _loadUserData().whenComplete(() {
      if (agentName != null && agentEmail != null && rolename != null) {
        _socketService.initSocket(agentName!, agentEmail!, rolename!,
            token: token);
        _socketService.onReceiveMessage(_handleIncomingMessage);
        _socketService.onGroupMessageReceived(_handleIcomingGroupMessage);
        _socketService.onGroupListUpdate(_handleBackgroundGroupMessage);
        _socketService.onIncomingCall(_handleIncomingCall);
        _socketService.onCallTerminated(_handleCallTermination);
        _socketService.onProductAdd(_handleProductAdd);
        _socketService.onProductUpdate(_handleProductUpdate);
        _socketService.onProductDelete(_handleProductDelete);
        //  _socketService.onDisconnect(_handleDisconnect);
        // _socketService.onConnect(_handleConnect);
      } else {
        debugPrint("Skipping socket init: agentName or agentEmail is null");
      }
    });
  }

  Future<void> reinitializeHive() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox('CREDENTIALS'),
      Hive.openBox("lastSeenTimeBox"),
      Hive.openBox('feedBox'),
      Hive.openBox("lastMessageMap"),
      Hive.openBox(LocalDbHelper.groupLastMessageBoxKey),
      Hive.openBox<int>(LocalDbHelper.groupChatUnreadCountKey),
      Hive.openBox<int>(LocalDbHelper.groupUnreadCountsBoxKey),
    ]);
  }

  Future<void> _forceLogout(String serverMessage) async {
    if (!mounted) return;
    final isAnotherDevice = serverMessage.toLowerCase().contains('another device');
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          isAnotherDevice ? Icons.devices_other_rounded : Icons.lock_clock_outlined,
          color: Colors.orange.shade700,
          size: 44,
        ),
        title: const Text('Session Ended'),
        content: Text(
          isAnotherDevice
              ? 'Your account was signed in on another device. This session has been ended for your security.'
              : 'You are no longer authorized. Please log in again.',
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Log In'),
          ),
        ],
      ),
    );
    await Hive.deleteFromDisk();
    await reinitializeHive();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      role = await LocalDbHelper.getUserType();
      agentEmail = LocalDbHelper.getEmail();

      if (role == "1") {
        rolename = "admin";
      } else if (role == "2") {
        rolename = "agent";
      } else if (role == "3") {
        rolename = "agent Head";
      }

      // Use cached profile for instant initialisation — socket can connect
      // immediately without waiting for a network round-trip.
      // Wrapped in its own try-catch; a Hive type-cast error must not prevent
      // the fallback API refresh from running.
      try {
        final cachedProfile = LocalDbHelper.getProfile();
        if (cachedProfile != null) {
          setState(() {
            agentName = cachedProfile.name ?? "";
            agentEmail = cachedProfile.email ?? agentEmail ?? "";
          });
          await _updateScreens();
        }
      } catch (e) {
        debugPrint('[MarketingHost] Cached profile load failed, falling back to API: $e');
      }

      // Trigger group data for the Feeds tab at startup — always, so cached
      // groups are served immediately even when offline (splash skips group
      // fetch when offline, leaving GroupProvider empty).
      if (mounted && agentEmail != null) {
        final groupProvider = Provider.of<GroupProvider>(context, listen: false);
        groupProvider.fetchAllGroups();
        groupProvider.fetchUsersGroups(agentEmail!);
      }

      // Background-refresh profile from API when online; handles force-logout.
      if (ConnectivityService.instance.isOnline) {
        await _refreshProfileInBackground();
      }
    } catch (error) {
      debugPrint('Error in _loadUserData: $error');
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _socketService.offCallTerminated(_handleCallTermination);
    super.dispose();
  }

  /// Called when connectivity is restored while the host is open.
  /// Re-initialises socket, refreshes the token, and silently re-fetches
  /// stale provider data — no shimmer, no UI disruption.
  Future<void> _onInternetRestored() async {
    if (!mounted) return;

    // 1. Refresh token silently
    final oldToken = await LocalDbHelper.getToken();
    if (oldToken != null) {
      final response = await auth.refreshToken(oldToken);
      if (response['message'] == "Refresh token generated successfully") {
        await LocalDbHelper.saveToken(response['token']);
        await LocalDbHelper.saveLastRefreshTime(DateTime.now().millisecondsSinceEpoch);
      }
    }

    final token = await LocalDbHelper.getToken();

    // 2. Re-initialise socket if it is not yet connected
    if (!_socketService.isConnected &&
        agentName != null &&
        agentEmail != null &&
        rolename != null) {
      _socketService.initSocket(agentName!, agentEmail!, rolename!, token: token);
      _socketService.onReceiveMessage(_handleIncomingMessage);
      _socketService.onGroupMessageReceived(_handleIcomingGroupMessage);
      _socketService.onGroupListUpdate(_handleBackgroundGroupMessage);
      _socketService.onIncomingCall(_handleIncomingCall);
      _socketService.onCallTerminated(_handleCallTermination);
      _socketService.onProductAdd(_handleProductAdd);
      _socketService.onProductUpdate(_handleProductUpdate);
      _socketService.onProductDelete(_handleProductDelete);
    }

    if (!mounted) return;

    // 3. Re-fetch providers silently (cache already shown; this updates in background)
    Provider.of<MarketingProductProvider>(context, listen: false)
        .fetchProducts(isRefresh: true);
    Provider.of<GroupProvider>(context, listen: false)
        .fetchAllGroups(forceRefresh: true);

    // 4. Background-refresh profile in case it was loaded from cache offline
    _refreshProfileInBackground();
  }

  Future<void> _refreshProfileInBackground() async {
    try {
      final userData = await auth.getUserInfo();
      if (userData is Map<String, dynamic>) {
        final message = userData['message'];
        if (message == "Session expired due to login on another device" ||
            message == "You are Not Authorized") {
          await _forceLogout(message);
          return;
        }
        if (message is Map<String, dynamic>) {
          final profile = Profile.fromJson(message);
          await LocalDbHelper.saveProfile(profile);
          if (mounted) {
            setState(() {
              agentName = profile.name ?? agentName;
              agentEmail = profile.email ?? agentEmail;
            });
            // Fresh-install path: no cached profile existed, so _updateScreens()
            // was never called from _loadUserData(). Build screens now that we
            // have the profile from the API — prevents the blank IndexedStack.
            if (_screens.isEmpty) {
              await _updateScreens();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[MarketingHost] Background profile refresh failed: $e');
    }
  }

  Future<void> _updateScreens() async {
    setState(() {
      _screens = [
        if (role == "1")
          AdminHome(
            agentEmail: agentEmail ?? "admin@gmail.com",
            agentName: agentName ?? "admin",
          )
        else
          MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => AssignedCustomersProvider(
                  agentEmail: agentEmail!,
                  agentName: agentName!,
                  socketService: _socketService,
                ),
              ),
            ],
            child: AgentHomeScreen(),
          ),
        FeedsScreen(loggedAgentEmail: agentEmail!),
        CustomerInquiriesPage(),
        MarketingProductScreen(),
        if (role == "1" || role == "3") AdminProfilePage() else ProfileScreen(),
      ];
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshCustomerInquiries();
      });
    }
  }

  Future<void> _refreshCustomerInquiries() async {
    if (!mounted) return;
    try {
      final provider = Provider.of<InquiryProvider>(context, listen: false);
      final role = await LocalDbHelper.getUserType();
      final currentUserEmail = LocalDbHelper.getProfile()?.email;
      await provider.fetchInquiries(
        userEmail: currentUserEmail,
        role: role,
        forceRefresh: true,
      );
    } catch (error) {
      debugPrint('Failed to refresh customer inquiries: $error');
    }
  }

  void _navigateToChat({
    required String? customername,
    required String customeremail,
    String? targetId,
  }) {
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AgentChatScreen(
          customerName: customername,
          customerEmail: customeremail,
          agentEmail: LocalDbHelper.getProfile()?.email ?? targetId,
          navigatorKey: widget.navigatorKey,
        ),
      ),
    );
  }

  // void _handleConnect() {
  //   if (_disconnectOverlay != null) {
  //     _disconnectOverlay?.remove();
  //     _disconnectOverlay = null;
  //   }
  // }

  // void _handleDisconnect() {
  //   if (_activeCallOverlay != null) {
  //     _activeCallOverlay?.remove();
  //     _activeCallOverlay = null;
  //   }

  //   final overlayState = Overlay.of(context);
  //   final overlayEntry = OverlayEntry(
  //     builder: (context) => Positioned(
  //       top: MediaQuery.of(context).padding.top + 10,
  //       left: 16,
  //       right: 16,
  //       child: Material(
  //         color: Colors.transparent,
  //         child: Container(
  //           padding: EdgeInsets.all(10),
  //           decoration: BoxDecoration(
  //             color: Colors.red,
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 'Connection Lost ',
  //                 style: TextStyle(color: Colors.white, fontSize: 16),
  //               ),
  //               SizedBox(height: 8),
  //               Text(
  //                 'Something went wrong. Please restart the app or check internet connection.',
  //                 style: TextStyle(color: Colors.white, fontSize: 14),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   _disconnectOverlay = overlayEntry;
  //   overlayState.insert(overlayEntry);
  // }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    _navigateToChat(
      customeremail: data["senderId"],
      customername: data["senderName"],
      targetId: data['targetId'],
    );
  }

  void _handleIcomingGroupMessage(Map<String, dynamic> data) {
    // Handled by InternalChatScreen when open; notifications handle the closed case.
    debugPrint(
        "[MarketingHost] Group message event — handled by InternalChatScreen or notification");
  }

  /// Called by SocketService whenever a group message arrives while the chat page is closed.
  /// Updates GroupProvider so badges stay current on any page.
  void _handleBackgroundGroupMessage() {
    if (!mounted) return;
    Provider.of<GroupProvider>(context, listen: false)
        .loadUnreadCountsFromStorage();
  }

  Future<void> _handleProductAdd(Map<String, dynamic> productData) async {
    debugPrint(
        "📦 [MarketingHost] Product added: ${productData['productName']}");
    if (!mounted) return;
    final product = Product.fromJson(productData);
    await Provider.of<MarketingProductProvider>(context, listen: false)
        .addOrUpdateProductLocal(product);
  }

  Future<void> _handleProductUpdate(Map<String, dynamic> productData) async {
    debugPrint(
        "🔄 [MarketingHost] Product updated: ${productData['productName']}");
    if (!mounted) return;
    final product = Product.fromJson(productData);
    await Provider.of<MarketingProductProvider>(context, listen: false)
        .addOrUpdateProductLocal(product);
  }

  Future<void> _handleProductDelete(String productId) async {
    debugPrint("🗑️ [MarketingHost] Product deleted: $productId");
    if (!mounted) return;
    await Provider.of<MarketingProductProvider>(context, listen: false)
        .deleteProductLocal(productId);
  }

  void _handleCallTermination(Map<String, dynamic> data) {
    final terminatedCallId = data['callId']?.toString();
    if (terminatedCallId == null || terminatedCallId.isEmpty) return;
    if (_activeIncomingCallId == terminatedCallId) {
      _activeIncomingCallId = null;
      CallKitService.instance.endCall(terminatedCallId);
    }
  }

  Future<void> _handleIncomingCall(Map<String, dynamic> callData) async {
    if (!mounted) return;
    final channelName = callData['channelName'] as String;
    final callerName = callData['callerName'] as String;
    final callerId = callData['callerId'] as String;
    final incomingCallId = callData['callId'].toString();
    _activeIncomingCallId = incomingCallId;
    final uid = Utils().generateIntUidFromEmail(agentEmail!);

    await CallKitService.instance.showIncomingCall(
      callId: incomingCallId,
      channelName: channelName,
      callerName: callerName,
      callerId: callerId,
      uid: uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: _screens.isEmpty
            ? const SizedBox.shrink()
            : IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
        bottomNavigationBar: MarketingNavBar(
          selectedIndex: _selectedIndex,
          onTabSelected: _onTabSelected,
        ),
      ),
    );

    return BackPressHandler(
      child: content,
    );
  }
}
