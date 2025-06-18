import 'dart:async';

class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final StreamController<Map<String, dynamic>> _streamController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get stream => _streamController.stream;

  void fireEvent(Map<String, dynamic> event) {
    _streamController.add(event);
  }
}
