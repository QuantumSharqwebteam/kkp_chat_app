import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

final FlutterBackgroundService service = FlutterBackgroundService();

// Global user credentials
Map<String, dynamic>? profile;
String? roleName;
String? email;
String? token;
String? name;

// Global socket instance
io.Socket? socket;
List<String> _roomMembers = [];
final _statusController = StreamController<List<String>>.broadcast();

const String notificationChannelId = 'kkp_chat_foreground';
const int notificationId = 888;

/// Initialize and maintain the socket connection.
Future<void> initSocketConnection() async {
  if (!_hasValidCredentials()) {
    debugPrint('Credentials missing. Skipping socket initialization.');
    return;
  }

  if (socket?.connected ?? false) {
    _joinIfNotInRoom();
    return;
  }

  socket = io.io('https://kkp-chat.onrender.com', {
    'transports': ['websocket'],
    'autoConnect': true,
    'reconnection': true,
  });

  socket?.onConnect((_) {
    debugPrint('Socket connected: ${socket?.id}');
    _emitJoin();
  });

  socket?.on('socketId', (id) => debugPrint('Socket ID: $id'));
  socket?.on('roomMembers', (members) {
    debugPrint('Room Members: $members');
    _updateRoomMembers(List<String>.from(members));
  });

  // Listen for incoming messages.
  socket?.on('receiveMessage', (data) {
    debugPrint('Message received: $data');
    handleIncomingMessage(data);
  });

  // Listen for incoming call events.
  socket?.on('incomingCall', (data) {
    debugPrint('Incoming call received: $data');
    handleIncomingCall(data);
  });
  socket?.on('callAnswered', (data) {
    debugPrint('Call answered: $data');
    handleCallAnswered(data);
  });
  socket?.on('callTerminated', (data) {
    debugPrint('Call terminated: $data');
    handleCallTerminated(data);
  });

  socket?.onDisconnect((_) async {
    debugPrint('Socket disconnected. Reinitializing...');
    await Future.delayed(Duration(seconds: 1));
    await initSocketConnection();
  });

  socket?.onError((error) => debugPrint('Socket error: $error'));
}

bool _hasValidCredentials() =>
    profile != null && roleName != null && token != null && email != null;

void _emitJoin() {
  if (!_hasValidCredentials()) {
    return;
  } else {
    socket?.emit('join', {
      'user': name,
      'userId': email,
      'role': roleName,
      'token': token,
    });
  }
}

void _joinIfNotInRoom() {
  if (!_roomMembers.contains(email)) {
    debugPrint('Re-joining room...');
    _emitJoin();
  } else {
    debugPrint('Already joined.');
  }
}

void _updateRoomMembers(List<String> newMembers) {
  if (_statusController.isClosed) return;

  final prev = Set<String>.from(_roomMembers);
  final curr = Set<String>.from(newMembers);
  for (final e in prev.difference(curr)) {
    LocalDbHelper.updateLastSeenTime(e);
    debugPrint("Updated last seen for $e");
  }

  _roomMembers = newMembers;
  _statusController.add(List.from(_roomMembers));
}

Future<void> initializeService() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const channel = AndroidNotificationChannel(
    notificationChannelId,
    'KKP Chat Service',
    description: 'Used for background chat activity',
    importance: Importance.low,
  );

  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'KKP Chat Service',
      initialNotificationContent: 'Initializing service...',
      foregroundServiceNotificationId: notificationId,
      autoStartOnBoot: true,
    ),
  );

  await setRoleName();
  service.startService();
}

Future<void> setRoleName() async {
  final role = profile?['role'];
  switch (role) {
    case "Admin":
      roleName = "admin";
      break;
    case "Agent":
      roleName = "agent";
      break;
    case "AgentHead":
      roleName = "head Agent";
      break;
    default:
      roleName = "User";
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox('CREDENTIALS'),
    Hive.openBox('lastSeenTimeBox'),
    Hive.openBox('feedBox'),
  ]);

  final box = Hive.box('CREDENTIALS');
  profile = Map<String, dynamic>.from(box.get("profile") ?? {});
  token = box.get('token');
  email = profile?['email'];
  name = profile?['name'];
  roleName = box.get("userType");

  debugPrint("Service started for: $email");

  final plugin = FlutterLocalNotificationsPlugin();

  await initSocketConnection();
  int joinAttempts = 0;

  Timer.periodic(Duration(seconds: 5), (timer) async {
    final connected = socket?.connected ?? false;
    if (!connected) {
      debugPrint('[Watchdog] Reconnecting...');
      await initSocketConnection();
    } else {
      final inRoom = _roomMembers.contains(email);
      if (!inRoom && joinAttempts < 10) {
        joinAttempts++;
        _emitJoin();
        debugPrint('[Watchdog] Attempting join $joinAttempts/10');
      }
    }

    plugin.show(
      notificationId,
      'KKP Chat Running',
      'Updated at ${DateTime.now()} - Socket: ${connected ? "Connected" : "Disconnected"}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          'KKP Chat Service',
          channelDescription: 'Keeps chat socket alive in background',
          icon: 'ic_bg_service_small',
          ongoing: true,
          silent: true,
          showProgress: true,
        ),
      ),
    );
  });
}

// ───────────────────── Message and Call Handlers ─────────────────────

Future<void> handleIncomingMessage(Map<String, dynamic> data) async {
  await showNotification(data);
  await saveMessageToHive(data);
}

Future<void> saveMessageToHive(Map<String, dynamic> data) async {
  final boxName = (roleName == "User")
      ? profile!['email']
      : '${profile!['email']}${data['senderId']}';
  final box = await Hive.openBox(boxName);

  final message = ChatMessageModel(
    message: data['message'] ?? "",
    timestamp: DateTime.now(),
    sender: data['senderId'] ?? "",
    type: data['type'] ?? 'text',
    mediaUrl: data['mediaUrl'] ?? "",
    form: data['form'] ?? "",
  );
  await box.add(message);
}

Future<void> showNotification(Map<String, dynamic> data) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const details = AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    channelDescription: 'your_channel_description',
    importance: Importance.max,
    priority: Priority.high,
  );

  await plugin.show(
    0,
    'New Message',
    data['message'] ?? '',
    const NotificationDetails(android: details),
  );
}

void handleIncomingCall(Map<String, dynamic> data) {
  debugPrint('Incoming call: $data');
}

void handleCallAnswered(Map<String, dynamic> data) {
  debugPrint('Call answered: $data');
}

void handleCallTerminated(Map<String, dynamic> data) {
  debugPrint('Call ended: $data');
}

// ───────────────────── Chat Message Model ─────────────────────

class ChatMessageModel {
  final String message;
  final String sender;
  final DateTime timestamp;
  final String? type;
  final String? mediaUrl;
  final Map<String, dynamic>? form;
  final String? callStatus;
  final String? callDuration;

  ChatMessageModel({
    required this.message,
    required this.sender,
    required this.timestamp,
    this.type,
    this.mediaUrl,
    this.form,
    this.callStatus,
    this.callDuration,
  });

  Map<String, dynamic> toMap() => {
        'message': message,
        'sender': sender,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'mediaUrl': mediaUrl,
        'form': form,
        'callStatus': callStatus,
        'callDuration': callDuration,
      };

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      message: map['message'],
      sender: map['sender'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      mediaUrl: map['mediaUrl'],
      form: map['form'] != null ? Map<String, dynamic>.from(map['form']) : null,
      callStatus: map['callStatus'],
      callDuration: map['callDuration'],
    );
  }
}
