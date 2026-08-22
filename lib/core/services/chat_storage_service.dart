import 'package:hive/hive.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';

class ChatStorageService {
  Future<Box> _openBox(String boxName) async {
    return await Hive.openBox(boxName);
  }

  /// Bounded, cursor-based read of a chat cache box.
  ///
  /// Returns at most [limit] messages, newest first, strictly older than
  /// [before] when supplied — the same contract as
  /// `ChatRepository.fetchCustomerMessages`, so a caller can swap between
  /// cache and network without reshaping the result.
  ///
  /// Unlike [getMessages], this honours [limit]. Box keys are ISO-8601
  /// timestamps (see [saveMessage] / [saveMessages]), so the window is selected
  /// by parsing keys and only [limit] values are decoded into models — decoding
  /// is the expensive part (`fromMap` copies maps and re-parses dates per row).
  /// Falls back to a full decode when any key is not a parseable timestamp, so
  /// this can never be less correct than the unbounded readers.
  Future<List<ChatMessageModel>> getMessageWindow(
    String boxName, {
    int limit = 20,
    DateTime? before,
  }) async {
    final box = await _openBox(boxName);
    if (box.isEmpty) return [];

    final dated = <MapEntry<dynamic, DateTime>>[];
    for (final key in box.keys) {
      final parsed = DateTime.tryParse(key.toString());
      if (parsed == null) {
        // Legacy / non-timestamp keys — fall back to the safe full decode.
        return _decodeAll(box, limit: limit, before: before);
      }
      dated.add(MapEntry(key, parsed));
    }

    // Compare by instant, never lexicographically: keys mix '...Z' (UTC) and
    // offset-free local forms, so string ordering would interleave them wrongly.
    dated.sort((a, b) => b.value.compareTo(a.value));

    final selected = <dynamic>[];
    for (final entry in dated) {
      if (before != null && !entry.value.isBefore(before)) continue;
      selected.add(entry.key);
      if (selected.length >= limit) break;
    }

    final messages = <ChatMessageModel>[];
    for (final key in selected) {
      final raw = box.get(key);
      if (raw == null) continue;
      messages.add(ChatMessageModel.fromMap(Map<String, dynamic>.from(raw)));
    }
    return messages;
  }

  List<ChatMessageModel> _decodeAll(Box box,
      {required int limit, DateTime? before}) {
    final allMessages = box.values
        .map((map) => ChatMessageModel.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (before == null) return allMessages.take(limit).toList();
    return allMessages
        .where((message) => message.timestamp.isBefore(before))
        .take(limit)
        .toList();
  }

  Future<List<ChatMessageModel>> getCustomerMessages(String boxName,
      {int limit = 20, String? before}) async {
    final box = await _openBox(boxName);
    final allMessages = box.values
        .map((map) => ChatMessageModel.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort(
          (a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first

    if (before != null) {
      final beforeDate = DateTime.parse(before);
      return allMessages
          .where((message) => message.timestamp.isBefore(beforeDate))
          .take(limit)
          .toList();
    } else {
      return allMessages.take(limit).toList();
    }
  }

  Future<void> saveMessage(ChatMessageModel message, String boxName) async {
    final box = await _openBox(boxName);
    final messageMap = message.toMap();
    await box.put(message.timestamp.toIso8601String(), messageMap);
  }

  Future<void> saveMessages(
      List<ChatMessageModel> messages, String boxName) async {
    final box = await _openBox(boxName);
    final messagesMap = messages.map((message) => message.toMap()).toList();
    await box.putAll(Map.fromEntries(
        messagesMap.map((message) => MapEntry(message['timestamp'], message))));
  }

  Future<int> compactMessages(String boxName) async {
    final box = await _openBox(boxName);
    final allMessages = box.values
        .map((map) => ChatMessageModel.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final uniqueMessages = <ChatMessageModel>[];
    final seenKeys = <String>{};
    for (final message in allMessages) {
      final key = _messageIdentity(message);
      if (seenKeys.add(key)) uniqueMessages.add(message);
    }

    if (uniqueMessages.length == allMessages.length) return 0;

    await box.clear();
    await box.putAll(Map.fromEntries(uniqueMessages.map(
      (message) =>
          MapEntry(message.timestamp.toIso8601String(), message.toMap()),
    )));
    return allMessages.length - uniqueMessages.length;
  }

  String _messageIdentity(ChatMessageModel message) {
    if (message.type == 'call' && message.callId?.isNotEmpty == true) {
      return 'call:${message.callId}';
    }
    if (message.messageId?.isNotEmpty == true) {
      return 'msg:${message.messageId}';
    }
    return 'ts:${message.timestamp.millisecondsSinceEpoch}';
  }

  Future<List<ChatMessageModel>> getMessages(String boxName,
      {int page = 1, int limit = 20}) async {
    final box = await _openBox(boxName);
    final allMessages = box.values
        .map((map) => ChatMessageModel.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort(
          (a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first

    final startIndex = (page - 1) * limit;
    if (startIndex >= allMessages.length) {
      return []; // Return an empty list if startIndex is out of range
    }
    return allMessages.sublist(startIndex); // Fetch all remaining messages
  }
}
