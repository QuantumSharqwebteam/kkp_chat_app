import 'package:kkpchatapp/core/constant.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Simple synchronization for Dart
void synchronized(Object lock, void Function() block) {
  block();
}

/// Log levels enum (lowerCamelCase for Dart lint)
enum LogLevel { debug, info, warning, error, fatal }

/// Extension to get uppercase name for logs
extension LogLevelExt on LogLevel {
  String get name => toString().split('.').last.toUpperCase();
}

/// Comprehensive logging service with centralized configuration
class LoggingService {
  static LoggingService? _instance;
  static final _lock = Object();

  Logger? _logger;
  bool _isInitialized = false;

  LoggingService._internal();

  static LoggingService get instance {
    if (_instance == null) {
      synchronized(_lock, () {
        _instance ??= LoggingService._internal();
      });
    }
    return _instance!;
  }

  /// Initialize the logging service
  Future<void> initialize() async {
    if (_isInitialized || !AppConstants.enableLogging) return;

    try {
      _logger = Logger(
        filter: _CustomLogFilter(),
        printer: _CustomLogPrinter(),
        output: _CustomLogOutput(),
      );

      _isInitialized = true;
      _log(LogLevel.info, 'LoggingService', 'Logging service initialized successfully');
    } catch (e) {
      if (kDebugMode) print('Failed to initialize logging service: $e');
    }
  }

  /// Internal logging
  void _log(
    LogLevel level,
    String source,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (!_isInitialized || !AppConstants.enableLogging) {
      if (kDebugMode) print('[$level] $source: $message');
      return;
    }

    if (!_shouldLog(level)) return;

    if (AppConstants.enableConsoleLogging) {
      _logToConsole(level, source, message, error, stackTrace);
    }

    // if (level == LogLevel.error || level == LogLevel.fatal) {
    //   _logToCrashlytics(level, source, message, error, stackTrace);
    // }
  }

  bool _shouldLog(LogLevel level) {
    if (!AppConstants.enableLogging) return false;

    final levelPriority = {
      LogLevel.debug: 0,
      LogLevel.info: 1,
      LogLevel.warning: 2,
      LogLevel.error: 3,
      LogLevel.fatal: 4,
    };

    final defaultLevel = _getLogLevelFromString(AppConstants.defaultLogLevel);
    return levelPriority[level]! >= levelPriority[defaultLevel]!;
  }

  LogLevel _getLogLevelFromString(String levelString) {
    switch (levelString.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warning':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      case 'fatal':
        return LogLevel.fatal;
      default:
        return LogLevel.info;
    }
  }

  void _logToConsole(
    LogLevel level,
    String source,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    switch (level) {
      case LogLevel.debug:
        _logger?.d('[$source] $message', error: error, stackTrace: stackTrace);
        break;
      case LogLevel.info:
        _logger?.i('[$source] $message', error: error, stackTrace: stackTrace);
        break;
      case LogLevel.warning:
        _logger?.w('[$source] $message', error: error, stackTrace: stackTrace);
        break;
      case LogLevel.error:
        _logger?.e('[$source] $message', error: error, stackTrace: stackTrace);
        break;
      case LogLevel.fatal:
        _logger?.f('[$source] $message', error: error, stackTrace: stackTrace);
        break;
    }
  }

  // void _logToCrashlytics(LogLevel level, String source, String message, [dynamic error, StackTrace? stackTrace]) {
  //   try {
  //     final crashlytics = FirebaseCrashlytics.instance;
  //     crashlytics.setCustomKey('log_level', level.name);
  //     crashlytics.setCustomKey('log_source', source);
  //     crashlytics.log('[$source] $message');

  //     if (error != null) {
  //       crashlytics.recordError(
  //         error,
  //         stackTrace,
  //         fatal: level == LogLevel.fatal,
  //         information: [
  //           DiagnosticsProperty('source', source),
  //           DiagnosticsProperty('level', level.name),
  //           DiagnosticsProperty('message', message),
  //         ],
  //       );
  //     }
  //   } catch (e) {
  //     if (kDebugMode) print('Failed to log to Crashlytics: $e');
  //   }
  // }

  // Public logging methods
  void debug(String source, String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.debug, source, message, error, stackTrace);
  void info(String source, String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.info, source, message, error, stackTrace);
  void warning(String source, String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.warning, source, message, error, stackTrace);
  void error(String source, String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, source, message, error, stackTrace);
  void fatal(String source, String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.fatal, source, message, error, stackTrace);

  // Category-specific logging
  void logApi(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(level, AppConstants.logCategoryApi, message, error, stackTrace);
  void logAuth(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(level, AppConstants.logCategoryAuth, message, error, stackTrace);
  void logUi(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(level, AppConstants.logCategoryUI, message, error, stackTrace);
  void logStorage(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(level, AppConstants.logCategoryStorage, message, error, stackTrace);
  void logNetwork(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(level, AppConstants.logCategoryNetwork, message, error, stackTrace);
  void logGeneral(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(level, AppConstants.logCategoryGeneral, message, error, stackTrace);

  // void recordCrash(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = true}) {
  //   try {
  //     final crashlytics = FirebaseCrashlytics.instance;
  //     if (reason != null) crashlytics.log('Manual crash report: $reason');
  //     crashlytics.recordError(error, stackTrace, fatal: fatal);
  //     _log(LogLevel.fatal, 'CrashReport', reason ?? 'Manual crash report', error, stackTrace);
  //   } catch (e) {
  //     if (kDebugMode) print('Failed to record crash: $e');
  //   }
  // }

  // void setUserId(String userId) {
  //   try {
  //     FirebaseCrashlytics.instance.setUserIdentifier(userId);
  //   } catch (e) {
  //     if (kDebugMode) print('Failed to set user ID in Crashlytics: $e');
  //   }
  // }

  // void setCustomKey(String key, dynamic value) {
  //   try {
  //     FirebaseCrashlytics.instance.setCustomKey(key, value);
  //   } catch (e) {
  //     if (kDebugMode) print('Failed to set custom key in Crashlytics: $e');
  //   }
  // }

  void dispose() => _isInitialized = false;
}

/// Custom log filter
class _CustomLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => AppConstants.enableLogging;
}

/// Custom log printer
class _CustomLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final color = _getColorForLevel(event.level);
    final timestamp =
        AppConstants.showTimestamp ? '[${DateTime.now().toString().substring(11, 19)}] ' : '';
    final levelStr = AppConstants.showLogLevel ? '[${event.level.name}] ' : '';
    final message = '$timestamp$levelStr${event.message}';
    if (AppConstants.enableColoredConsoleOutput && color != null) {
      return ['$color$message\x1B[0m'];
    }
    return [message];
  }

  String? _getColorForLevel(Level level) {
    if (!AppConstants.enableColoredConsoleOutput) return null;
    switch (level) {
      case Level.debug:
        return '\x1B[37m';
      case Level.info:
        return '\x1B[36m';
      case Level.warning:
        return '\x1B[33m';
      case Level.error:
        return '\x1B[31m';
      case Level.fatal:
        return '\x1B[35m';
      default:
        return null;
    }
  }
}

/// Custom log output
class _CustomLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    if (AppConstants.enableConsoleLogging) {
      for (final line in event.lines) {
        if (kDebugMode) print(line);
      }
    }
  }
}
