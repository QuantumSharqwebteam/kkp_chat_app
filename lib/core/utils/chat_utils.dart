import 'dart:math';

import 'package:intl/intl.dart';

class ChatUtils {
  String formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      final currentTime = DateTime.now();
      return DateFormat('hh:mm a').format(currentTime);
    }
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      final currentTime = DateTime.now();
      return DateFormat('hh:mm a').format(currentTime);
    }
  }

  int generateUniqueUId() {
    // Get current timestamp in milliseconds
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    // Generate a random number
    Random random = Random();
    int randomNumber = random.nextInt(1000000); // Adjust the range as needed

    // Combine timestamp and random number to create a unique ID
    // Use bitwise operations to ensure the combined value fits within an integer
    int uniqueId = timestamp ^ randomNumber;

    return uniqueId;
  }
}
