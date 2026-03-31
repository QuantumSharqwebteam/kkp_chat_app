import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
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
import 'package:kkpchatapp/logic/agent/marketing_product_provider.dart';
import 'package:kkpchatapp/logic/agent/agent_home_screen_provider.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/admin/screens/admin_home.dart';
import 'package:kkpchatapp/presentation/admin/screens/admin_profile_page.dart';
import 'package:kkpchatapp/presentation/admin/screens/customer_inquries.dart';
import 'package:kkpchatapp/presentation/admin/screens/internal_chat/internal_chat_screen.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common/chat/call_provider.dart';

import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/incoming_call_widget.dart';
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

class _MarketingHostState extends State<MarketingHost> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String? role;
  String? rolename;
  String? agentEmail;
  String? agentName;
  List<Widget> _screens = [];
  final SocketService _socketService = SocketService(navigatorKey);
  final chatRepository = ChatRepository();
  AuthApi auth = AuthApi();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  OverlayEntry? _activeCallOverlay;

  //OverlayEntry? _disconnectOverlay;

  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.removeObserver(this);
    _loadUserDataAndInitializeSocket().then((_) {
      _initializeNotificationService().then((_) {});
    });
    initCheck();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes if needed
  }

  void initCheck() async {
    // Set the global flag to true after initialization
    isAppInitialized = true;
  }

  Future<void> _initializeNotificationService() async {
    await NotificationService.init(context, _navigatorKey);
  }

  Future<void> _loadUserDataAndInitializeSocket() async {
    final token = await LocalDbHelper.getToken();
    await _loadUserData().whenComplete(() {
      if (agentName != null && agentEmail != null && rolename != null) {
        _socketService.initSocket(agentName!, agentEmail!, rolename!, token: token);
        _socketService.onReceiveMessage(_handleIncomingMessage);
        _socketService.onGroupMessageReceived(_handleIcomingGroupMessage);
        _socketService.onIncomingCall(_handleIncomingCall);
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
      // dotenv.load(fileName: "keys.env"), // Only if required again
    ]);
  }

  Future<void> _loadUserData() async {
    try {
      role = await LocalDbHelper.getUserType();
      agentEmail = LocalDbHelper.getEmail();

      debugPrint('Loaded role: $role, Loaded email: $agentEmail');

      if (role == "1") {
        rolename = "admin";
      } else if (role == "2") {
        rolename = "agent";
      } else if (role == "3") {
        rolename = "agent Head";
      }

      final userData = await auth.getUserInfo();

      if (userData is Map<String, dynamic>) {
        final message = userData['message'];

        if (message == "Session expired due to login on another device") {
          await Hive.deleteFromDisk();
          await reinitializeHive();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          }
          return;
        }

        if (message == "You are Not Authorized") {
          await Hive.deleteFromDisk();
          await reinitializeHive();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          }
          return;
        }

        if (message is Map<String, dynamic>) {
          final profile = Profile.fromJson(message);
          await LocalDbHelper.saveProfile(profile).whenComplete(() {
            debugPrint('Loaded profile: $profile');
          });

          setState(() {
            agentName = profile.name ?? "";
            agentEmail = profile.email ?? "";
          });

          await _updateScreens();
        } else {
          debugPrint("Unexpected message type: $message");
        }
      } else {
        debugPrint("Unexpected userData format: $userData");
      }
    } catch (error) {
      debugPrint('Error in _loadUserData: $error');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer?.stop();
    // _socketService.disconnect(); // Disconnect when leaving the host screen
    super.dispose();
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
  }

  void _navigateToChat({
    required String? customername,
    required String customeremail,
    String? targetId,
  }) {
    Navigator.push(
      widget.navigatorKey.currentContext!,
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
    Navigator.push(widget.navigatorKey.currentContext!, MaterialPageRoute(builder: (context) {
      return InternalChatScreen(
          agentName: data["senderName"],
          agentEmail: data["senderId"],
          navigatorKey: widget.navigatorKey);
    }));
  }

  Future<void> _handleProductAdd(Map<String, dynamic> productData) async {
    debugPrint("📦 [MarketingHost] Product added: ${productData['productName']}");
    if (!mounted) return;
    final product = Product.fromJson(productData);
    await Provider.of<MarketingProductProvider>(context, listen: false)
        .addOrUpdateProductLocal(product);
  }

  Future<void> _handleProductUpdate(Map<String, dynamic> productData) async {
    debugPrint("🔄 [MarketingHost] Product updated: ${productData['productName']}");
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

  void _handleIncomingCall(Map<String, dynamic> callData) {
    // debugPrint("Incoming call data2: ${callData.toString()}");
    // Remove previous overlay if exists
    _activeCallOverlay?.remove();
    _activeCallOverlay = null;

    final channelName = callData['channelName'];
    final callerName = callData['callerName'];
    final callerId = callData['callerId'];
    final incomingCallId = callData["callId"];
    final uid = Utils().generateIntUidFromEmail(agentEmail!);
    final overlayState = Overlay.of(context);

    late OverlayEntry overlayEntry;
    Timer? timeoutTimer;
    _audioPlayer?.stop();
    _audioPlayer = AudioPlayer();
    Future<void> stopAndRemoveOverlay() async {
      try {
        debugPrint("🛑 Stopping ringtone...");

        await _audioPlayer?.stop();
        debugPrint("✅ Ringtone stopped");
      } catch (e) {
        debugPrint("⚠️ Failed to stop ringtone: $e");
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
            await _audioPlayer?.stop();
            await Future.delayed(const Duration(milliseconds: 100));
            await chatRepository.updateCallData(incomingCallId, "not answered");
            // Optionally emit reject event
            _socketService.terminateCall(
              targetId: callerId,
              callId: incomingCallId,
              channelName: channelName,
            );
          },
          audioPlayer: _audioPlayer!,
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
      // Optionally emit missed call
      await chatRepository.updateCallData(incomingCallId, "missed");
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: IndexedStack(
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
