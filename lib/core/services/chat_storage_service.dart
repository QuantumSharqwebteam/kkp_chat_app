import 'package:hive/hive.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';

class ChatStorageService {
  Future<Box> _openBox(String boxName) async {
    return await Hive.openBox(boxName);
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

  Future<List<ChatMessageModel>> getMessages(String boxName) async {
    final box = await _openBox(boxName);
    return box.values
        .map((map) => ChatMessageModel.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Stream<List<ChatMessageModel>> watchMessages(String boxName) async* {
    final box = await _openBox(boxName);
    yield* box.watch().asyncMap((_) => getMessages(boxName));
  }
}
