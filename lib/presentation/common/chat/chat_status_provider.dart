import 'package:flutter/material.dart';

class ChatStatusProvider with ChangeNotifier {
  bool _receiverIsOnChatPage = false;

  bool get receiverIsOnChatPage => _receiverIsOnChatPage;

  void setReceiverIsOnChatPage(bool isOnChatPage) {
    _receiverIsOnChatPage = isOnChatPage;
    notifyListeners();
  }
}
