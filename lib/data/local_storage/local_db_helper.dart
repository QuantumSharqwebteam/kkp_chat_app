import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/data/models/call_log_model.dart';
import 'package:kkpchatapp/data/models/group_message_model.dart';
import 'package:kkpchatapp/data/models/group_model.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/models/product_model.dart';

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

  // Group chat box key
  static const String _groupChatBoxKey = 'groupChatBox';
  //group chat unread count
  static const String _groupChatUnreadCountKey = 'groupChatUnreadCount';

  // launguage selected
  static const String _localeKey = 'locale';

  // Product-related keys and methods
  static const String _productBoxKey = 'productBox';
  static const String _lastProductFetchTimeKey = 'lastProductFetchTime';

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

  static Future<void> saveProfile(Profile profile) async {
    await _box.put(_profile, profile.toMap());
  }

  static Profile? getProfile() {
    final profileMap = _box.get(_profile);
    if (profileMap != null && profileMap is Map<String, dynamic>) {
      return Profile.fromMap(profileMap);
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
        await box.add(product.toCreateJson());
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
      final products = productMaps.map((map) => Product.fromJson(map)).toList();
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
        (map) => map['productId'] == product.productId,
      );
      if (existingIndex != -1) {
        // Update existing product
        await box.putAt(existingIndex, product.toCreateJson());
        debugPrint("✅ [LocalDbHelper] Product updated: ${product.productName}");
      } else {
        // Add new product
        await box.add(product.toCreateJson());
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
        (map) => map['productId'] == productId,
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

// Open or create the group chat box
  static Future<Box<dynamic>> _openGroupChatBox() async {
    //   debugPrint("📦 [LocalDbHelper] Opening group chat box...");
    return await Hive.openBox<dynamic>(_groupChatBoxKey);
  }

// Save a group message
  static Future<void> saveGroupMessage(GroupMessageModel message) async {
    //  debugPrint("💾 [LocalDbHelper] Saving group message: ${message.messageId}");
    final box = await _openGroupChatBox();
    await box.put(message.messageId, message.toMap());
    // debugPrint("✅ [LocalDbHelper] Group message saved successfully!");
  }

// Get all group messages
  static Future<List<GroupMessageModel>> getGroupMessages() async {
    debugPrint("📥 [LocalDbHelper] Fetching all group messages...");
    final box = await _openGroupChatBox();
    final groupMessages =
        box.values.map((map) => GroupMessageModel.fromMap(Map<String, dynamic>.from(map))).toList();
    debugPrint("📋 [LocalDbHelper] Found ${groupMessages.length} group messages");
    return groupMessages;
  }

// Delete a group message
  static Future<void> deleteGroupMessage(String messageId) async {
    debugPrint("🗑️ [LocalDbHelper] Deleting group message: $messageId");
    final box = await _openGroupChatBox();
    await box.delete(messageId);
    debugPrint("✅ [LocalDbHelper] Group message deleted successfully!");
  }

// Update a group message (e.g., mark as deleted)
  static Future<void> updateGroupMessage(GroupMessageModel message) async {
    debugPrint("🔄 [LocalDbHelper] Updating group message: ${message.messageId}");
    final box = await _openGroupChatBox();
    await box.put(message.messageId, message.toMap());
    debugPrint("✅ [LocalDbHelper] Group message updated successfully!");
  }

// Clear all group messages
  static Future<void> clearGroupMessages() async {
    debugPrint("🧹 [LocalDbHelper] Clearing all group messages...");
    final box = await _openGroupChatBox();
    await box.clear();
    debugPrint("✅ [LocalDbHelper] All group messages cleared successfully!");
  }

  // Add these methods for group chat unread count management

  /// Get the current unread count for group chat
  static Future<int> getGroupChatUnreadCount() async {
    try {
      final box = await Hive.openBox<int>(_groupChatUnreadCountKey);
      return box.get('count') ?? 0; // Use null-coalescing operator to handle null
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Error getting group chat unread count: $e");
      return 0; // Return default value on error
    }
  }

  /// Increment the unread count for group chat
  static Future<void> incrementGroupChatUnreadCount() async {
    try {
      final box = await Hive.openBox<int>(_groupChatUnreadCountKey);
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
      final box = await Hive.openBox<int>(_groupChatUnreadCountKey);
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
      final box = await Hive.openBox<int>(_groupChatUnreadCountKey);
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
      await Hive.openBox<int>(_groupChatUnreadCountKey);
      debugPrint("✅ [LocalDbHelper] Initialized group chat unread count box");
    } catch (e) {
      debugPrint("❌ [LocalDbHelper] Error initializing group chat unread count box: $e");
      rethrow;
    }
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
}
