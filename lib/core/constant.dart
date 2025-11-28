class AppConstants {
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double cardElevation = 2.0;

  // Padding Constants
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingLSmall = 12.0;
  static const double paddingMedium = 16.0;
  static const double paddingLMedium = 15.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Spacing Constants
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Border Radius Constants
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // Button Heights
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Logging Configuration
  static const bool enableLogging = true;
  static const bool enableConsoleLogging = true;
  static const bool enableColoredConsoleOutput = true;

  // Log Levels
  static const String logLevelDebug = 'DEBUG';
  static const String logLevelInfo = 'INFO';
  static const String logLevelWarning = 'WARNING';
  static const String logLevelError = 'ERROR';
  static const String logLevelFatal = 'FATAL';

  // Default log level (DEBUG, INFO, WARNING, ERROR, FATAL)
  static const String defaultLogLevel = logLevelDebug;

  // Console Logging Configuration
  static const bool showTimestamp = true;
  static const bool showLogLevel = true;
  static const bool showSourceInfo = true;
  static const String timestampFormat = 'yyyy-MM-dd HH:mm:ss.SSS';

  // Log Categories
  static const String logCategoryApi = 'API';
  static const String logCategoryAuth = 'AUTH';
  static const String logCategoryUI = 'UI';
  static const String logCategoryStorage = 'STORAGE';
  static const String logCategoryNetwork = 'NETWORK';
  static const String logCategoryGeneral = 'GENERAL';
}
