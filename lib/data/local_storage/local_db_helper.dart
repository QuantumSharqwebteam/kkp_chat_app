import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/data/models/call_log_model.dart';
import 'package:kkpchatapp/data/models/group_message_model.dart';
import 'package:kkpchatapp/data/models/group_model.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/models/form_data_model.dart';

class LocalDbHelper {
  static const String _keyToken = 'token';
  static const String _userType = 'userType';
  static const String _name = 'name';
  static const String _email = 'email';
  static const String _profile = 'profile';
  static const String _fCMToken = "FCMTOKEN";
  static const String _lastRefreshTime = 'lastRefreshTime';
  static const String _lastMessageMapKey = 'lastMessageMap';
  static const String unreadCountsBoxKey = 'unreadCountsBox';
  static const String _receiverOnChatPageKey = 'receiverOnChatPage';
  static const String _hasSeenOnboardingKey = 'hasSeenOnboarding';

  // Group chat box key (per-group: groupChatBox_<groupId>)
  static const String _groupChatBoxKey = 'groupChatBox';
  // Group last message box (keyed by groupId) — public so main.dart can pre-open it
  static const String groupLastMessageBoxKey = 'groupLastMessageBox';
  // Global group chat unread count (legacy, kept for background handler)
  static const String groupChatUnreadCountKey = 'groupChatUnreadCount';
  // Per-group unread counts (keyed by groupId inside the box)
  static const String groupUnreadCountsBoxKey = 'groupUnreadCountsBox';

  // launguage selected
  static const String _localeKey = 'locale';

  // Product-related keys and methods
  static const String _productBoxKey = 'productBox';
  static const String _lastProductFetchTimeKey = 'lastProductFetchTime';
  static const String _inquiryFormsBoxKey = 'inquiryFormsBox';

  // feed
  static const String _pinnedAgentsKey = 'pinnedAgents';
  static const String _lastSeenMapKey = 'lastSeenMap';

  static Box<dynamic> get _box => Hive.box('CREDENTIALS');
  // for storing user last seen time or when he/ she came online
  static Box<dynamic> get _lastSeenBoxInstance => Hive.box("lastSeenTimeBox");

  static Box<dynamic> get _lastMessageBoxInstance => Hive.box(_lastMessageMapKey);

  static Box<dynamic> get _feedBox => Hive.box('feedBox');

  static Future<void> saveToken(String token) async {
    await _box.put(_keyToken, token);
  }

  static Future<String?> getToken() async {
    return _box.get(_keyToken);
  }

  static Future<void> removeToken() async {
    await _box.delete(_keyToken);
  }

  static Future<void> saveEmail(String email) async {
    await _box.put(_email, email);
  }

  static String? getEmail() {
    return _box.get(_email);
  }

  static Future<void> removeEmail() async {
    await _box.delete(_email);
  }

  static Future<void> saveUserType(String userType) async {
    await _box.put(_userType, userType);
  }

  static Future<String?> getUserType() async {
    return _box.get(_userType);
  }

  static Future<void> removeUserType() async {
    await _box.delete(_userType);
  }

  static Future<void> saveName(String name) async {
    await _box.put(_name, name);
  }

  static String? getName() {
    return _box.get(_name);
  }

  static Future<void> removeName() async {
    await _box.delete(_name);
  }

  static Future<void> setOnboardingSeen(bool value) async {
    await _box.put(_hasSeenOnboardingKey, value);
  }

  static Future<bool> hasSeenOnboarding() async {
    return _box.get(_hasSeenOnboardingKey, defaultValue: false) as bool;
  }

  static Future<void> saveProfile(Profile profile) async {
    await _box.put(_profile, profile.toMap());
  }

  static Profile? getProfile() {
    try {
      final profileMap = _box.get(_profile);
      if (profileMap is Map) {
        // Round-trip through JSON so all nested Hive maps (_Map<dynamic,dynamic>)
        // become properly typed Map<String,dynamic> before Profile.fromMap() runs.
        final jsonStr = jsonEncode(Map<String, dynamic>.from(profileMap));
        return Profile.fromMap(jsonDecode(jsonStr) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] getProfile error: $e");
    }
    return null;
  }

  static String? getProfileId() {
    return getProfile()?.id;
  }

  static Future<void> removeProfile() async {
    await _box.delete(_profile);
  }

  // Methods to handle last seen times
  static Future<void> updateLastSeenTime(String email) async {
    await _lastSeenBoxInstance.put(email, DateTime.now().toIso8601String());
  }

  static DateTime? getLastSeenTime(String email) {
    String? lastSeen = _lastSeenBoxInstance.get(email);
    if (lastSeen != null) {
      DateTime parsedDate = DateTime.parse(lastSeen);
      return parsedDate;
    }
    return null;
  }

  static Future<void> clearLastSeenMap() async {
    await _lastSeenBoxInstance.delete(_lastSeenMapKey);
  }

  // pinned agents
  static Future<void> savePinnedAgents(Set<String> agentEmails) async {
    await _feedBox.put(_pinnedAgentsKey, agentEmails.toList());
  }

  static Set<String> getPinnedAgents() {
    final List<dynamic>? emails = _feedBox.get(_pinnedAgentsKey);
    return emails != null ? Set<String>.from(emails) : {};
  }

  static Future<void> clearPinnedAgents() async {
    await _feedBox.delete(_pinnedAgentsKey);
  }

  static Future<void> saveFCMToken(String fcmToken) async {
    await _box.put(_fCMToken, fcmToken);
  }

  static String? getFCMToken() {
    return _box.get(_fCMToken);
  }

  static Future<void> clearFCMToken() async {
    await _box.delete(_fCMToken);
  }

  static Future<void> saveLastRefreshTime(int time) async {
    await _box.put(_lastRefreshTime, time);
  }

  static Future<int?> getLastRefreshTime() async {
    return _box.get(_lastRefreshTime);
  }

  static Future<void> saveCallLogs(List<CallLogModel> callLogs) async {
    final email = getProfile()?.email;
    if (email != null) {
      final box = await Hive.openBox<String>('callLogs_$email');
      await box.clear();
      for (var log in callLogs) {
        await box.add(jsonEncode(log.toJson()));
      }
    }
  }

  static Future<List<CallLogModel>> getCallLogs() async {
    final email = getProfile()?.email;
    if (email != null) {
      final box = await Hive.openBox<String>('callLogs_$email');
      return box.values.map((log) => CallLogModel.fromJson(jsonDecode(log))).toList();
    }
    return [];
  }

  static Future<void> updateCallLogs(List<CallLogModel> newCallLogs) async {
    final email = getProfile()?.email;
    if (email != null) {
      final box = await Hive.openBox<String>('callLogs_$email');
      final existingLogs = box.values.map((log) => CallLogModel.fromJson(jsonDecode(log))).toList();
      final updatedLogs = [...existingLogs, ...newCallLogs];
      await box.clear();
      for (var log in updatedLogs) {
        await box.add(jsonEncode(log.toJson()));
      }
    }
  }

  // Method to update the last message for a user
  static Future<void> updateLastMessage(String email, String message) async {
    await _lastMessageBoxInstance.put(email, message);
  }

  // Method to retrieve the last message for a user
  static String? getLastMessage(String email) {
    return _lastMessageBoxInstance.get(email);
  }

  // Method to clear all last messages
  static Future<void> clearLastMessages() async {
    await _lastMessageBoxInstance.clear();
  }

  static Future<void> updateUnreadCount(String agentEmail, String customerEmail, int count) async {
    final box = await Hive.openBox<int>('${unreadCountsBoxKey}_$agentEmail');
    await box.put(customerEmail, count);
  }

  static Future<int?> getUnreadCount(String agentEmail, String customerEmail) async {
    final box = await Hive.openBox<int>('${unreadCountsBoxKey}_$agentEmail');
    return box.get(customerEmail, defaultValue: 0);
  }

  static Future<void> clearUnreadCount(String agentEmail, String customerEmail) async {
    final box = await Hive.openBox<int>('${unreadCountsBoxKey}_$agentEmail');
    await box.put(customerEmail, 0);
  }

  static Future<void> incrementUnreadCount(String agentEmail, String customerEmail) async {
    final box = await Hive.openBox<int>('${unreadCountsBoxKey}_$agentEmail');
    final currentCount = box.get(customerEmail, defaultValue: 0);
    await box.put(customerEmail, currentCount! + 1);
  }

  // Add this method to save the receiver's chat page status
  static Future<void> saveReceiverOnChatPageStatus(bool isOnChatPage) async {
    await _lastSeenBoxInstance.put(_receiverOnChatPageKey, isOnChatPage);
    debugPrint("💾 Saved receiver on chat page status: $isOnChatPage");
  }

  // Add this method to retrieve the receiver's chat page status
  static bool? getReceiverOnChatPageStatus() {
    bool? status = _lastSeenBoxInstance.get(_receiverOnChatPageKey);
    debugPrint("🔍 Retrieved receiver on chat page status: $status");
    return status;
  }

  // Save product list to Hive as Map<String, dynamic>
  static Future<void> saveProducts(List<Product> products) async {
    try {
      debugPrint("💾 [LocalDbHelper] Saving ${products.length} products to Hive...");
      final box = await Hive.openBox<dynamic>(_productBoxKey);
      await box.clear();
      for (var product in products) {
        await box.add(product.toJson());
      }
      await _box.put(_lastProductFetchTimeKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint("✅ [LocalDbHelper] Products saved successfully!");
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to save products: $e");
      rethrow;
    }
  }

  // Get product list from Hive as Map<String, dynamic> and convert to Product
  static Future<List<Product>> getProducts() async {
    try {
      debugPrint("📦 [LocalDbHelper] Fetching products from Hive...");
      final box = await Hive.openBox<dynamic>(_productBoxKey);
      final productMaps = box.values.toList();
      final products = productMaps.map((map) {
        if (map is Map) {
          return Product.fromJson(Map<String, dynamic>.from(map));
        }
        return Product.fromJson({});
      }).toList();
      debugPrint("📋 [LocalDbHelper] Found ${products.length} products in Hive.");
      return products;
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to fetch products: $e");
      rethrow;
    }
  }

// Check if products were fetched in the current app session
  static Future<bool> isProductFetchRequired() async {
    try {
      final lastFetchTime = _box.get(_lastProductFetchTimeKey);
      if (lastFetchTime == null) {
        debugPrint("🔄 [LocalDbHelper] No cached products found. Fetch required.");
        return true; // Never fetched before
      }
      debugPrint("🗂️ [LocalDbHelper] Cached products found. Fetch not required.");
      return false;
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to check fetch requirement: $e");
      rethrow;
    }
  }

// Clear product list from Hive
  static Future<void> clearProducts() async {
    try {
      debugPrint("🧹 [LocalDbHelper] Clearing products from Hive...");
      final box = await Hive.openBox<Product>(_productBoxKey);
      await box.clear();
      await _box.delete(_lastProductFetchTimeKey);
      debugPrint("✅ [LocalDbHelper] Products cleared successfully!");
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to clear products: $e");
      rethrow;
    }
  }

  // Add or update a single product in Hive as Map<String, dynamic>
  static Future<void> addOrUpdateProduct(Product product) async {
    try {
      debugPrint("🔄 [LocalDbHelper] Adding/updating product: ${product.productName}");
      final box = await Hive.openBox<dynamic>(_productBoxKey);
      final productMaps = box.values.toList();
      final existingIndex = productMaps.indexWhere(
        (map) =>
            map['productId']?.toString() == product.productId?.toString() ||
            map['_id']?.toString() == product.productId?.toString(),
      );
      if (existingIndex != -1) {
        // Update existing product
        await box.putAt(existingIndex, product.toJson());
        debugPrint("✅ [LocalDbHelper] Product updated: ${product.productName}");
      } else {
        // Add new product
        await box.add(product.toJson());
        debugPrint("✅ [LocalDbHelper] Product added: ${product.productName}");
      }
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to add/update product: $e");
      rethrow;
    }
  }

  // Delete a product by its ID
  static Future<void> deleteProduct(String productId) async {
    try {
      debugPrint("🗑️ [LocalDbHelper] Deleting product with ID: $productId");
      final box = await Hive.openBox<dynamic>(_productBoxKey);
      final productMaps = box.values.toList();
      final existingIndex = productMaps.indexWhere(
        (map) =>
            map['productId']?.toString() == productId.toString() ||
            map['_id']?.toString() == productId.toString(),
      );
      if (existingIndex != -1) {
        await box.deleteAt(existingIndex);
        debugPrint("✅ [LocalDbHelper] Product deleted successfully!");
      } else {
        debugPrint("⚠️ [LocalDbHelper] Product with ID $productId not found.");
      }
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to delete product: $e");
      rethrow;
    }
  }

  static Future<void> saveLocale(Locale locale) async {
    await _box.put(_localeKey, "${locale.languageCode}_${locale.countryCode}");
  }

  static Locale? getLocale() {
    final stored = _box.get(_localeKey);
    if (stored != null && stored is String) {
      final parts = stored.split("_");
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      } else if (parts.length == 1) {
        return Locale(parts[0]);
      }
    }
    return null;
  }

  static Future<void> clearLocale() async {
    await _box.delete(_localeKey);
  }

  // Returns the Hive box name for a specific group's messages
  static String _groupChatBoxName(String groupId) => '${_groupChatBoxKey}_$groupId';

  // Save a message into the group-specific box
  static Future<void> saveGroupMessage(GroupMessageModel message, String groupId) async {
    debugPrint("💾 [LocalDbHelper] Saving message ${message.messageId} → group: $groupId");
    final box = await Hive.openBox<dynamic>(_groupChatBoxName(groupId));
    await box.put(message.messageId, message.toMap());
  }

  // Get all messages for a specific group
  static Future<List<GroupMessageModel>> getGroupMessages(String groupId) async {
    debugPrint("📥 [LocalDbHelper] Loading messages for group: $groupId");
    final box = await Hive.openBox<dynamic>(_groupChatBoxName(groupId));
    final groupMessages =
        box.values.map((map) => GroupMessageModel.fromMap(Map<String, dynamic>.from(map))).toList();
    debugPrint("📋 [LocalDbHelper] Found ${groupMessages.length} local messages for group: $groupId");
    return groupMessages;
  }

  // Delete a single message from a group's box
  static Future<void> deleteGroupMessage(String messageId, String groupId) async {
    debugPrint("🗑️ [LocalDbHelper] Deleting message: $messageId from group: $groupId");
    final box = await Hive.openBox<dynamic>(_groupChatBoxName(groupId));
    await box.delete(messageId);
  }

  // Update (overwrite) a message in a group's box
  static Future<void> updateGroupMessage(GroupMessageModel message, String groupId) async {
    debugPrint("🔄 [LocalDbHelper] Updating message: ${message.messageId} in group: $groupId");
    final box = await Hive.openBox<dynamic>(_groupChatBoxName(groupId));
    await box.put(message.messageId, message.toMap());
  }

  // Clear all messages for a specific group
  static Future<void> clearGroupMessages(String groupId) async {
    debugPrint("🧹 [LocalDbHelper] Clearing messages for group: $groupId");
    final box = await Hive.openBox<dynamic>(_groupChatBoxName(groupId));
    await box.clear();
  }

  // Save the last message preview for a group (used by the group list tile)
  static Future<void> saveGroupLastMessage(
      String groupId, String message, DateTime timestamp) async {
    final box = await Hive.openBox<dynamic>(groupLastMessageBoxKey);
    await box.put(groupId, {
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    });
    debugPrint("💾 [LocalDbHelper] Saved last message for group $groupId: \"$message\"");
  }

  // Get the last message preview for a group (returns null if none saved)
  static Future<({String message, DateTime? timestamp})> getGroupLastMessage(
      String groupId) async {
    final box = await Hive.openBox<dynamic>(groupLastMessageBoxKey);
    final data = box.get(groupId);
    if (data is Map) {
      final msg = data['message']?.toString() ?? '';
      final ts = data['timestamp'] != null ? DateTime.tryParse(data['timestamp'].toString()) : null;
      return (message: msg, timestamp: ts);
    }
    return (message: '', timestamp: null);
  }

  // Add these methods for group chat unread count management

  /// Get the current unread count for group chat
  static Future<int> getGroupChatUnreadCount() async {
    try {
      final box = await Hive.openBox<int>(groupChatUnreadCountKey);
      return box.get('count') ?? 0; // Use null-coalescing operator to handle null
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Error getting group chat unread count: $e");
      return 0; // Return default value on error
    }
  }

  /// Increment the unread count for group chat
  static Future<void> incrementGroupChatUnreadCount() async {
    try {
      final box = await Hive.openBox<int>(groupChatUnreadCountKey);
      int currentCount = box.get('count') ?? 0; // Use null-coalescing operator
      await box.put('count', currentCount + 1);
      debugPrint("✅ [LocalDbHelper] Incremented group chat unread count to ${currentCount + 1}");
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Error incrementing group chat unread count: $e");
      rethrow;
    }
  }

  /// Set a specific unread count for group chat
  static Future<void> setGroupChatUnreadCount(int count) async {
    try {
      final box = await Hive.openBox<int>(groupChatUnreadCountKey);
      await box.put('count', count);
      debugPrint("✅ [LocalDbHelper] Set group chat unread count to $count");
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Error setting group chat unread count: $e");
      rethrow;
    }
  }

  /// Clear the unread count for group chat
  static Future<void> clearGroupChatUnreadCount() async {
    try {
      final box = await Hive.openBox<int>(groupChatUnreadCountKey);
      await box.put('count', 0);
      debugPrint("✅ [LocalDbHelper] Cleared group chat unread count");
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Error clearing group chat unread count: $e");
      rethrow;
    }
  }

  /// Initialize group chat unread count box if it doesn't exist
  static Future<void> initializeGroupChatUnreadCount() async {
    try {
      // Try to open the box, it will be created if it doesn't exist
      await Hive.openBox<int>(groupChatUnreadCountKey);
      debugPrint("✅ [LocalDbHelper] Initialized group chat unread count box");
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Error initializing group chat unread count box: $e");
      rethrow;
    }
  }

  // --- Per-group unread counts ---

  static Future<int> getGroupUnreadCount(String groupId) async {
    final box = await Hive.openBox<int>(groupUnreadCountsBoxKey);
    return box.get(groupId, defaultValue: 0)!;
  }

  static Future<void> incrementGroupUnreadCount(String groupId) async {
    final box = await Hive.openBox<int>(groupUnreadCountsBoxKey);
    final current = box.get(groupId, defaultValue: 0)!;
    await box.put(groupId, current + 1);
    debugPrint("📈 [LocalDbHelper] Group $groupId unread count: ${current + 1}");
  }

  static Future<void> clearGroupUnreadCount(String groupId) async {
    final box = await Hive.openBox<int>(groupUnreadCountsBoxKey);
    await box.put(groupId, 0);
    debugPrint("🧹 [LocalDbHelper] Cleared unread count for group $groupId");
  }

  // Helper method to ensure we have a valid count
  // static Future<int> _getValidCount(int? count) async {
  //   return count ?? 0;
  // }

  // Save groups to Hive
  static Future<void> saveGroups(List<GroupModel> groups) async {
    try {
      final box = await Hive.openBox<dynamic>('groupsBox');
      await box.clear();
      for (var group in groups) {
        await box.add(group.toJson());
      }
      await _box.put('lastGroupsFetchTime', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to save groups: $e");
      rethrow;
    }
  }

// Get groups from Hive
  static Future<List<GroupModel>?> getGroups() async {
    try {
      final box = await Hive.openBox<dynamic>('groupsBox');
      final groupsJson = box.values.toList();
      if (groupsJson.isEmpty) return null;
      return groupsJson.map((json) {
        return GroupModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to get groups: $e");
      return null;
    }
  }

// Get groups timestamp
  static Future<int?> getGroupsTimestamp() async {
    return _box.get('lastGroupsFetchTime');
  }

// Save user groups to Hive
  static Future<void> saveUserGroups(List<GroupModel> userGroups) async {
    try {
      final box = await Hive.openBox<dynamic>('userGroupsBox');
      await box.clear();
      for (var group in userGroups) {
        await box.add(group.toJson());
      }
      await _box.put('lastUserGroupsFetchTime', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to save user groups: $e");
      rethrow;
    }
  }

// Get user groups from Hive
  static Future<List<GroupModel>?> getUserGroups() async {
    try {
      final box = await Hive.openBox<dynamic>('userGroupsBox');
      final userGroupsJson = box.values.toList();
      if (userGroupsJson.isEmpty) return null;
      return userGroupsJson.map((json) {
        return GroupModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to get user groups: $e");
      return null;
    }
  }

// Get user groups timestamp
  static Future<int?> getUserGroupsTimestamp() async {
    return _box.get('lastUserGroupsFetchTime');
  }

  // --- AWS Keys cache (stored in the existing CREDENTIALS box) ---
  static const String _awsAccessKey = 'aws_access_key';
  static const String _awsSecretKey = 'aws_secret_key';
  static const String _awsRegion = 'aws_region';
  static const String _awsCacheTime = 'aws_key_cache_time';
  static const Duration _awsCacheDuration = Duration(days: 1);

  static bool isAwsKeysCacheValid() {
    final cached = _box.get(_awsCacheTime);
    if (cached == null) return false;
    final fetchedAt = DateTime.tryParse(cached as String);
    return fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _awsCacheDuration;
  }

  static Future<void> saveAwsKeys({
    required String accessKey,
    required String secretKey,
    required String region,
  }) async {
    await _box.put(_awsAccessKey, accessKey);
    await _box.put(_awsSecretKey, secretKey);
    await _box.put(_awsRegion, region);
    await _box.put(_awsCacheTime, DateTime.now().toIso8601String());
  }

  static ({String? accessKey, String? secretKey, String? region}) getAwsKeys() {
    return (
      accessKey: _box.get(_awsAccessKey) as String?,
      secretKey: _box.get(_awsSecretKey) as String?,
      region: _box.get(_awsRegion) as String?,
    );
  }

  static Future<Box<dynamic>> _inquiryFormsBox() async {
    return await Hive.openBox<dynamic>(_inquiryFormsBoxKey);
  }

  static Future<void> saveInquiryForms(String email, List<FormDataModel> forms) async {
    try {
      final box = await _inquiryFormsBox();
      final serialized = forms.map((form) => form.toMap()).toList();
      await box.put(email, serialized);
      debugPrint("✅ [LocalDbHelper] Cached ${forms.length} inquiry forms for $email");
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to cache inquiry forms: $e");
    }
  }

  static Future<List<FormDataModel>> getInquiryForms(String email) async {
    try {
      final box = await _inquiryFormsBox();
      final stored = box.get(email);
      if (stored is List) {
        final List<FormDataModel> forms = [];
        for (var item in stored) {
          if (item is Map) {
            forms.add(FormDataModel.fromJson(Map<String, dynamic>.from(item)));
          } else if (item is String) {
            final json = jsonDecode(item);
            if (json is Map) {
              forms.add(FormDataModel.fromJson(Map<String, dynamic>.from(json)));
            }
          }
        }
        return forms;
      }
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to read cached inquiry forms: $e");
    }
    return [];
  }

  static Future<void> clearInquiryForms(String email) async {
    try {
      final box = await _inquiryFormsBox();
      await box.delete(email);
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to clear cached inquiry forms: $e");
    }
  }

  // --- Assigned customers cache (stored in the existing CREDENTIALS box) ---

  static Future<void> saveAssignedCustomers(
      String agentEmail, List<dynamic> customers) async {
    try {
      final serialized = customers
          .map((c) => c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{})
          .toList();
      // Use jsonEncode/Decode so nested maps stay properly typed on read-back
      await _box.put('assignedCustomers_$agentEmail', jsonEncode(serialized));
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to save assigned customers: $e");
    }
  }

  // Synchronous — _box is already open (CREDENTIALS), so no async needed.
  // Returning synchronously lets AssignedCustomersProvider set state before
  // the first widget build, eliminating the shimmer entirely.
  static List<dynamic> getAssignedCustomers(String agentEmail) {
    try {
      final raw = _box.get('assignedCustomers_$agentEmail');
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return List<dynamic>.from(
              decoded.map((c) => c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{}));
        }
      }
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Failed to get assigned customers: $e");
    }
    return [];
  }
}
