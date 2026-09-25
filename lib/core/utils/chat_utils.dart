import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ChatUtils {
  // Constructing a DateFormat is the expensive part (locale lookup + pattern
  // tokenization), not formatting with it. These used to be allocated per call,
  // and a chat row calls into here up to 6 times per rebuild.
  // Safe as process-lifetime statics: Intl.defaultLocale is never assigned
  // anywhere in the app, so a formatter built at first use cannot go stale.
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static const Uuid _uuid = Uuid();

  /// Allocation-free path for chat rows — avoids the
  /// DateTime -> ISO String -> DateTime round-trip that [formatTimestamp]
  /// forces on callers that already hold a DateTime.
  static String timeLabel(DateTime dateTime) =>
      _timeFormat.format(dateTime.toLocal());

  String formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return _timeFormat.format(DateTime.now());
    }
    try {
      return _timeFormat.format(DateTime.parse(timestamp).toLocal());
    } catch (e) {
      return _timeFormat.format(DateTime.now());
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final local = date.isUtc ? date.toLocal() : date;
    final messageDate = DateTime(local.year, local.month, local.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return _dateFormat.format(local);
    }
  }

  String generateMessageId() {
    return _uuid.v4(); // Use the uuid package to generate a unique ID
  }
}
