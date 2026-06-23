import 'package:hive/hive.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';

class ChatStorageService {
  Future<Box> _openBox(String boxName) async {
    return await Hive.openBox(boxName);
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
      (message) => MapEntry(message.timestamp.toIso8601String(), message.toMap()),
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
