import 'package:hive/hive.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';

class ChatStorageService {
  Future<Box> _openBox(String boxName) async {
    return await Hive.openBox(boxName);
  }

  Future<List<ChatMessageModel>> getCustomerMessages(String boxName,
      {int page = 1, int limit = 20}) async {
    final box = await _openBox(boxName);
    final allMessages = box.values
        .map((map) => ChatMessageModel.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort(
          (a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first

    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    if (startIndex >= allMessages.length) {
      return []; // Return an empty list if startIndex is out of range
    }
    return allMessages.sublist(startIndex,
        endIndex > allMessages.length ? allMessages.length : endIndex);
  }

  Future<void> saveMessage(ChatMessageModel message, String boxName) async {
    final box = await _openBox(boxName);
    final messageMap = message.toMap();
    await box.put(message.timestamp.toString(), messageMap);
  }

  Future<void> saveMessages(
      List<ChatMessageModel> messages, String boxName) async {
    final box = await _openBox(boxName);
    final messagesMap = messages.map((message) => message.toMap()).toList();
    await box.putAll(Map.fromEntries(
        messagesMap.map((message) => MapEntry(message['timestamp'], message))));
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
