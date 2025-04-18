import 'package:hive/hive.dart';
import 'package:kkp_chat_app/data/models/profile_model.dart';

class LocalDbHelper {
  static const String _keyToken = 'token';
  static const String _userType = 'userType';
  static const String _name = 'name';
  static const String _email = 'email';
  static const String _profile = 'profile';

  // feed
  static const String _pinnedAgentsKey = 'pinnedAgents';
  static const String _lastSeenMapKey = 'lastSeenMap';

  static Box<dynamic> get _box => Hive.box('CREDENTIALS');
  // for storing user last seen time or when he/ she came online
  static Box<dynamic> get _lastSeenBoxInstance => Hive.box("lastSeenTimeBox");

  static Box<dynamic> get _feedBox => Hive.box('feedBox');

  static Future<void> saveToken(String token) async {
    await _box.put(_keyToken, token);
  }

  static String? getToken() {
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

  static String? getUserType() {
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
    return Profile.fromMap(_box.get(_profile));
  }

  static Future<void> removeProfile() async {
    await _box.delete(_profile);
  }

  // Methods to handle last seen times
  static Future<void> updateLastSeenTime(String email) async {
    await _lastSeenBoxInstance.put(email, DateTime.now().toIso8601String());
    // if (kDebugMode) {
    //   debugPrint("📂 Hive last seen data: ${_lastSeenBoxInstance.toMap()}");
    // }
  }

  static DateTime? getLastSeenTime(String email) {
    String? lastSeen = _lastSeenBoxInstance.get(email);
    if (lastSeen != null) {
      DateTime parsedDate = DateTime.parse(lastSeen);
      // debugPrint(
      //     "📅 Retrieved last seen time from Hive for $email: $parsedDate");
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
}
