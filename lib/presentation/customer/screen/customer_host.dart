import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kkpchatapp/data/api/auth_service.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/logic/customer/customer_home_provider.dart';
import 'package:kkpchatapp/logic/customer/customer_product_provider.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common/chat/call_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/back_press_handler.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/incoming_call_widget.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_home_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_products_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_profile_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/customer_settings_page.dart';
import 'package:kkpchatapp/presentation/customer/widget/customer_nav_bar.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_chat_screen.dart';
import 'package:provider/provider.dart';

class CustomerHost extends StatefulWidget {
  const CustomerHost({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<CustomerHost> createState() => _CustomerHostState();
}

class _CustomerHostState extends State<CustomerHost> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  late final SocketService _socketService;
  AuthApi auth = AuthApi();
  final chatRepository = ChatRepository();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Profile? profile;

  OverlayEntry? _activeCallOverlay;
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();

    _socketService = SocketService(widget.navigatorKey);
    _loadCurrentUserData().then((_) async {
      final token = await LocalDbHelper.getToken();

      if (profile != null) {
        _socketService.initSocket(
          profile!.name!,
          profile!.email!,
          "User",
          token: token,
        );
        _socketService.onReceiveMessage(_handleIncomingMessage);
        _socketService.onIncomingCall(_handleIncomingCall);
        _socketService.onProductAdd(_handleProductAdd);
        _socketService.onProductUpdate(_handleProductUpdate);
        _socketService.onProductDelete(_handleProductDelete);
        await _initializeNotificationService();
        _handleFirebaseNotificationTaps();

        initCheck();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes if needed
  }

  void initCheck() async {
    // Set the global flag to true after initialization
    isAppInitialized = true;
  }

  // Handle product add event
  Future<void> _handleProductAdd(Map<String, dynamic> productData) async {
    debugPrint("[CustomerHost] New product added: ${productData['productName']}");
    final product = Product.fromJson(productData);
    if (mounted) {
      final homeProvider = Provider.of<CustomerHomeProvider>(context, listen: false);
      final productProvider = Provider.of<CustomerProductProvider>(context, listen: false);
      await homeProvider.addOrUpdateProductLocal(product);
      await productProvider.refreshProductsFromHive();
    }
  }

  // Handle product update event
  Future<void> _handleProductUpdate(Map<String, dynamic> productData) async {
    debugPrint("[CustomerHost] Product updated: ${productData['productName']}");
    final product = Product.fromJson(productData);
    if (mounted) {
      final homeProvider = Provider.of<CustomerHomeProvider>(context, listen: false);
      final productProvider = Provider.of<CustomerProductProvider>(context, listen: false);
      await homeProvider.addOrUpdateProductLocal(product);
      await productProvider.refreshProductsFromHive();
    }
  }

  // Handle product delete event
  Future<void> _handleProductDelete(String productId) async {
    debugPrint("[CustomerHost] Product deleted: $productId");
    if (mounted) {
      final homeProvider = Provider.of<CustomerHomeProvider>(context, listen: false);
      final productProvider = Provider.of<CustomerProductProvider>(context, listen: false);
      await homeProvider.deleteProductLocal(productId);
      await productProvider.refreshProductsFromHive();
    }
  }

  void _handleFirebaseNotificationTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('🔔 Notification opened (background/terminated): ${message.data}');

      if (isAppInitialized) {
        final agentName = message.data['senderName'];
        final customerEmail = profile!.email;
        final customerImage = profile!.profileUrl ?? "";

        final userType = await LocalDbHelper.getUserType();
        if (userType == "0") {
          _navigateToChat(
            name: agentName,
            email: customerEmail,
            image: customerImage,
          );
        }
      } else {
        debugPrint("App is not initialized. Skipping notification handling.");
      }
    });
  }

  void _navigateToChat({
    required String? name,
    required String? email,
    required String? image,
  }) {
    Navigator.push(
        widget.navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (_) => CustomerChatScreen(
            agentName: name,
            customerEmail: email,
            navigatorKey: widget.navigatorKey,
          ),
        ));
  }

  Future<void> _initializeNotificationService() async {
    await NotificationService.init(
      context,
      _navigatorKey,
      onNotificationClick: (agentName, customerEmail, customerImage) async {
        String? userType = await LocalDbHelper.getUserType();
        if (userType == "0" && profile != null) {
          _navigateToChat(
            name: agentName,
            email: customerEmail,
            image: customerImage,
          );
        }
      },
    );
  }

  Future<void> reinitializeHive() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox('CREDENTIALS'),
      Hive.openBox("lastSeenTimeBox"),
      Hive.openBox('feedBox'),
      Hive.openBox("lastMessageMap"),
      // dotenv.load(fileName: "keys.env"), // Only if required again
    ]);
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final userData = await auth.getUserInfo();
      if (userData['message'] == "Session expired due to login on another device") {
        await Hive.deleteFromDisk();
        await reinitializeHive();
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
            return LoginPage();
          }));
        }
      }

      if (userData["message"] == "You are Not Authorized") {
        await Hive.deleteFromDisk();
        await reinitializeHive();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
        return;
      }

      profile = Profile.fromJson(userData['message']);
      if (profile != null) {
        await LocalDbHelper.saveProfile(profile!);
      } else {
        debugPrint("SAVE PROFILE FAILED DUE TO NULL");
      }
    } catch (error) {
      debugPrint('Error in _loadCurrentUserData: $error');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Remove listener
    _socketService.disconnect();
    super.dispose();
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final agentName = data['senderName'];
    final customerEmail = profile!.email;
    final customerImage = profile!.profileUrl ?? "";

    _navigateToChat(
      name: agentName,
      email: customerEmail,
      image: customerImage,
    );
  }

  void _handleIncomingCall(Map<String, dynamic> callData) {
    // Remove previous overlay if exists
    _activeCallOverlay?.remove();
    _activeCallOverlay = null;

    final channelName = callData['channelName'];
    final callerName = callData['callerName'];
    final callerId = callData['callerId'];
    final incomingCallId = callData["callId"];
    final uid = Utils().generateIntUidFromEmail(profile!.email!);
    final overlayState = Overlay.of(context);

    late OverlayEntry overlayEntry;
    Timer? timeoutTimer;
    // ✅ Ensure previous player is stopped before creating new one
    _audioPlayer?.stop();
    _audioPlayer = AudioPlayer();

    Future<void> stopAndRemoveOverlay() async {
      try {
        if (_audioPlayer != null) {
          debugPrint("🛑 Attempting to stop ringtone...");

          await _audioPlayer!.stop();
          await _audioPlayer!.setSource(AssetSource('')); // 👈 Important for iOS
          debugPrint("✅ Ringtone stopped");

          await _audioPlayer!.release();
          await _audioPlayer!.dispose();
          debugPrint("✅ AudioPlayer released and disposed");
        } else {
          debugPrint("⚠️ AudioPlayer already null or disposed");
        }
      } catch (e) {
        debugPrint("❌ Failed to stop/release ringtone: $e");
      }

      timeoutTimer?.cancel();
      overlayEntry.remove();
      _activeCallOverlay = null;
      _audioPlayer = null;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: IncomingCallWidget(
          audioPlayer: _audioPlayer!,
          callerName: callerName,
          onAnswer: () async {
            await stopAndRemoveOverlay();
            if (context.mounted) {
              context.read<CallProvider>().startNewCall(
                  channelName: channelName,
                  remoteUserName: callerName,
                  uid: uid,
                  callId: incomingCallId,
                  isCaller: false);
            }
          },
          onReject: () async {
            await stopAndRemoveOverlay();
            await chatRepository.updateCallData(incomingCallId, "not answered");
            // Optionally emit reject event
            _socketService.terminateCall(
              targetId: callerId,
              callId: incomingCallId,
              channelName: channelName,
            );
          },
        ),
      ),
    );

    _activeCallOverlay = overlayEntry;
    overlayState.insert(overlayEntry);

    // If the app is not in the foreground, also show a notification
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      NotificationService.showIncomingCallNotification(callerName);
    }

    // Auto-dismiss after 30 seconds
    timeoutTimer = Timer(const Duration(seconds: 30), () async {
      await stopAndRemoveOverlay();
      await chatRepository.updateCallData(incomingCallId, "missed");
      // Optionally emit missed call
    });
  }

  final List<Widget> _screens = [
    CustomerHomePage(),
    CustomerProductsPage(),
    CustomerProfilePage(),
    CustomerSettingsPage(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, callProvider, child) {
        Widget content = GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
            bottomNavigationBar: CustomerNavBar(
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
        );
        return BackPressHandler(child: content);
      },
    );
  }
}

