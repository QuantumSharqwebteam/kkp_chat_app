import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta')
  ];

  /// The title of the application displayed in the AppBar and splash screen
  ///
  /// In en, this message translates to:
  /// **'KKP Chat App'**
  String get appTitle;

  /// Text for the login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Text for the sign up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// Welcome message on the home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to KKP Chat'**
  String get welcome;

  /// Text for the logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Label for language switcher dropdown
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// Label for email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Placeholder for email input field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Text for forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Text for sign-up prompt
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an Account?'**
  String get dontHaveAccount;

  /// Placeholder for email input field (alternative)
  ///
  /// In en, this message translates to:
  /// **'Enter your Email'**
  String get enterYourEmail;

  /// Placeholder for password input field
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Message for password reset instruction
  ///
  /// In en, this message translates to:
  /// **'No worries! Enter your email address below, and we will send you a link to reset your password'**
  String get resetPasswordMessage;

  /// Text for submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Error message for invalid email format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validEmailError;

  /// Text for back to login link
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// Error message for empty email field
  ///
  /// In en, this message translates to:
  /// **'Email can\'t be empty'**
  String get emailEmptyError;

  /// Title for new password creation screen
  ///
  /// In en, this message translates to:
  /// **'Create new Password'**
  String get createNewPassword;

  /// Rule for new password creation
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from the previously used password'**
  String get newPasswordRule;

  /// Label for password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Label for new password field
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Label for confirm new password input field
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// Label for password input field
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get enterPasswordLabel;

  /// Label for re-enter password input field
  ///
  /// In en, this message translates to:
  /// **'Re-enter Password'**
  String get reEnterPassword;

  /// Text for reset password button
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Text for create account button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Label for full name input field
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Placeholder for full name input field
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// Label for create password input field
  ///
  /// In en, this message translates to:
  /// **'Create a Password'**
  String get createPassword;

  /// Label for confirm password input field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Text for login prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an Account?'**
  String get alreadyHaveAccount;

  /// Title for email verification screen
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerification;

  /// Message for verification code sent
  ///
  /// In en, this message translates to:
  /// **'We have sent the six-digit verification code to'**
  String get verificationCodeSent;

  /// Error message for invalid verification code
  ///
  /// In en, this message translates to:
  /// **'Invalid code, please try again'**
  String get invalidCodeError;

  /// Error message for wrong OTP code
  ///
  /// In en, this message translates to:
  /// **'Wrong OTP code, please try again'**
  String get wrongOTPError;

  /// Text for resend OTP prompt
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the OTP?'**
  String get didntReceiveOTP;

  /// Text for resend OTP button
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// Message for no available agents
  ///
  /// In en, this message translates to:
  /// **'No agents available'**
  String get noAgentsAvailable;

  /// Label for ongoing call status
  ///
  /// In en, this message translates to:
  /// **'Ongoing Call'**
  String get ongoingCall;

  /// Label for incoming call status
  ///
  /// In en, this message translates to:
  /// **'Incoming Call'**
  String get incomingCall;

  /// Label for incoming call notification
  ///
  /// In en, this message translates to:
  /// **'Incoming call from:'**
  String get incomingCallFrom;

  /// Title for call history screen
  ///
  /// In en, this message translates to:
  /// **'Call History'**
  String get callHistory;

  /// Title for privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Text for privacy policy agreement
  ///
  /// In en, this message translates to:
  /// **'By using KKP chat application, you agree to the'**
  String get privacyPolicyAgreement;

  /// Description of the app's purpose
  ///
  /// In en, this message translates to:
  /// **'A smart and efficient chat-based solution that connects customers with marketing agents in real time. Instantly manage inquiries, check stock availability, and track orders—all in one place. Empowering businesses with seamless communication and actionable insights.'**
  String get appDescription;

  /// Tagline for the app
  ///
  /// In en, this message translates to:
  /// **'Instant Inquiries,\nSeamless Sales.'**
  String get appTagline;

  /// Text for terms and privacy policy agreement
  ///
  /// In en, this message translates to:
  /// **'By using KKP chat application, you agree to the Terms and Privacy Policy'**
  String get termsAndPrivacyAgreement;

  ///
  ///
  /// In en, this message translates to:
  /// **'At KKP chat app, we respect your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, share, and safeguard your data when you use our chat application. By using our services, you agree to the terms outlined in this policy.\n\nThe collected data is used to provide seamless messaging services, enhance app security, analyze usage patterns, and improve customer support. Your messages are end-to-end encrypted to maintain confidentiality, and we implement security measures like secure cloud storage and restricted data access to protect your information. We do not sell or share your personal data with third-party advertisers. However, data may be shared with legal authorities if required by law or to prevent fraud and security threats.\n\nFor any questions or concerns regarding this Privacy Policy, you can contact us at support@kkpchatapp.com. By continuing to use KKP Chat App, you acknowledge and agree to the terms outlined in this policy.'**
  String get privacyPolicyFullText;

  /// Label for agent
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agent;

  /// Prompt for user to choose an action
  ///
  /// In en, this message translates to:
  /// **'Choose what to do:'**
  String get chooseWhatToDo;

  /// Option to unsend a message
  ///
  /// In en, this message translates to:
  /// **'Unsend Message'**
  String get unsendMessage;

  /// Title for the About Us section
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// Company name
  ///
  /// In en, this message translates to:
  /// **'KKP'**
  String get kKP;

  /// Description of KKP company
  ///
  /// In en, this message translates to:
  /// **'KKP is a leading name in the textile industry, known for quality yarn production and smart supply chain management. With years of trusted service, we bring transparency, innovation, and reliability to every process.'**
  String get kKPDescription;

  /// Title for Who We Are section
  ///
  /// In en, this message translates to:
  /// **'Who We Are'**
  String get whoWeAre;

  /// Introduction for Who We Are section
  ///
  /// In en, this message translates to:
  /// **'We’re a textile-focused company delivering:'**
  String get whoWeAreDescription;

  /// Bullet point for premium quality yarn
  ///
  /// In en, this message translates to:
  /// **'• Premium quality yarn'**
  String get premiumQualityYarn;

  /// Bullet point for timely deliveries
  ///
  /// In en, this message translates to:
  /// **'• Timely deliveries'**
  String get timelyDeliveries;

  /// Bullet point for transparent operations
  ///
  /// In en, this message translates to:
  /// **'• Transparent operations'**
  String get transparentOperations;

  /// Description of the platform's purpose
  ///
  /// In en, this message translates to:
  /// **'Our platform connects agents, buyers, and mills in one unified system—making order management easier than ever.'**
  String get platformDescription;

  /// Title for Our Mission section
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get ourMission;

  /// Statement of the company's mission
  ///
  /// In en, this message translates to:
  /// **'To simplify textile operations with speed, clarity, and digital tools.'**
  String get missionStatement;

  /// Title for Our Vision section
  ///
  /// In en, this message translates to:
  /// **'Our Vision'**
  String get ourVision;

  /// Statement of the company's vision
  ///
  /// In en, this message translates to:
  /// **'To be the leading tech-powered solution in the textile industry.'**
  String get visionStatement;

  /// Title for about section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Example user name
  ///
  /// In en, this message translates to:
  /// **'John'**
  String get john;

  /// Information about account authenticity
  ///
  /// In en, this message translates to:
  /// **'To help keep our community authentic, we’re showing information about accounts on KKP app. People can see this by tapping on your profile and choosing \'About this account\'.'**
  String get accountAuthenticityInfo;

  /// Label for date joined
  ///
  /// In en, this message translates to:
  /// **'Date joined'**
  String get dateJoined;

  /// Example date joined
  ///
  /// In en, this message translates to:
  /// **'February 2025'**
  String get february2025;

  /// Title for account and security section
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get accountAndSecurity;

  /// Title for the Login & Recovery section
  ///
  /// In en, this message translates to:
  /// **'Login & Recovery'**
  String get loginAndRecovery;

  /// Label for managing password
  ///
  /// In en, this message translates to:
  /// **'Manage your password'**
  String get manageYourPassword;

  /// Label for login preference and recovery methods
  ///
  /// In en, this message translates to:
  /// **', Login preference and recovery methods'**
  String get loginPreferenceAndRecovery;

  /// Button label for changing password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Label for permanently deleting account
  ///
  /// In en, this message translates to:
  /// **'Delete Account Permanently'**
  String get deleteAccountPermanently;

  /// Title for confirming account deletion
  ///
  /// In en, this message translates to:
  /// **'Confirm Account Deletion'**
  String get confirmAccountDeletion;

  /// Label for reason for deleting the account
  ///
  /// In en, this message translates to:
  /// **'Reason for deleting the account'**
  String get reasonForDeleting;

  /// Label for confirming deletion
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// Confirmation message for permanent account deletion
  ///
  /// In en, this message translates to:
  /// **'By entering email and password you confirm that this account can be permanently deleted, and cannot be recovered in any way.'**
  String get deleteAccountConfirmation;

  /// Label for email input field in account deletion
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Label for password input field in account deletion
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Label for archive action
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// Placeholder for search input field
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// Label for delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Error message for empty fields
  ///
  /// In en, this message translates to:
  /// **'Fields cannot be empty!'**
  String get fieldsCannotBeEmpty;

  /// Success message for password change
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get passwordChangedSuccessfully;

  /// Loading message during password change
  ///
  /// In en, this message translates to:
  /// **'Please wait while the password is being changed.'**
  String get pleaseWaitPasswordChange;

  /// Title for password and security section
  ///
  /// In en, this message translates to:
  /// **'Password and Security'**
  String get passwordAndSecurity;

  /// Label for current password field
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// Label for retype new password field
  ///
  /// In en, this message translates to:
  /// **'Retype New Password'**
  String get retypeNewPassword;

  /// Error message for empty subject field in complaints
  ///
  /// In en, this message translates to:
  /// **'Subject cannot be empty'**
  String get subjectCannotBeEmpty;

  /// Error message for empty description field in complaints
  ///
  /// In en, this message translates to:
  /// **'Description cannot be empty'**
  String get descriptionCannotBeEmpty;

  /// Success message for complaint submission
  ///
  /// In en, this message translates to:
  /// **'Complaint submitted successfully'**
  String get complaintSubmittedSuccessfully;

  /// Title for complaints section
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaints;

  /// Label for subject field in complaints
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// Label for description field in complaints
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Button label for submitting complaint
  ///
  /// In en, this message translates to:
  /// **'Submit Complaint'**
  String get submitComplaint;

  /// Title for settings section
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for language/locale selection
  ///
  /// In en, this message translates to:
  /// **'Change locale:'**
  String get changeLocale;

  /// Title for account and orders section
  ///
  /// In en, this message translates to:
  /// **'Account & your orders'**
  String get accountAndOrders;

  /// Title for account management section
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get accountManagement;

  /// Title for password change section
  ///
  /// In en, this message translates to:
  /// **'Password Change'**
  String get passwordChange;

  /// Title for order enquiries section
  ///
  /// In en, this message translates to:
  /// **'Order Enquires'**
  String get orderEnquires;

  /// Description for order enquiries tracking feature
  ///
  /// In en, this message translates to:
  /// **'Track All Order Enquires in One Place'**
  String get trackAllOrderEnquires;

  /// Title for preferences section
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// Title for notifications section
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Description for notifications hub
  ///
  /// In en, this message translates to:
  /// **'Your Notifications Hub'**
  String get yourNotificationsHub;

  /// Title for complaints management
  ///
  /// In en, this message translates to:
  /// **'Manage Complaints'**
  String get manageComplaints;

  /// Title for terms and policy section
  ///
  /// In en, this message translates to:
  /// **'Terms & Policy'**
  String get termsAndPolicy;

  /// Title for terms and policy management
  ///
  /// In en, this message translates to:
  /// **'Manage Terms & Policy'**
  String get manageTermsAndPolicy;

  /// Button label for logging out
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// Confirmation message when push notifications are enabled
  ///
  /// In en, this message translates to:
  /// **'Push notifications enabled.'**
  String get pushNotificationsEnabled;

  /// Error message when notification permission is denied
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please enable from settings.'**
  String get permissionDenied;

  /// Title for notification settings section
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Label for push notifications toggle for messages
  ///
  /// In en, this message translates to:
  /// **'Push Notifications for messages'**
  String get pushNotificationsForMessages;

  /// Button label to enable push notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Push Notifications'**
  String get enablePushNotifications;

  /// Message when push notifications are disabled
  ///
  /// In en, this message translates to:
  /// **'Push notifications are disabled. Enable to receive alerts.'**
  String get pushNotificationsDisabled;

  /// Error message when unable to open app settings
  ///
  /// In en, this message translates to:
  /// **'Could not open app settings.'**
  String get couldNotOpenAppSettings;

  /// Title for order enquiries section
  ///
  /// In en, this message translates to:
  /// **'Order Enquiries'**
  String get orderEnquiries;

  /// Label for search functionality
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Product name for cotton t-shirt
  ///
  /// In en, this message translates to:
  /// **'Cotton T-Shirt'**
  String get cottonTShirt;

  /// Title for new products section
  ///
  /// In en, this message translates to:
  /// **'New Products'**
  String get newProducts;

  /// Title for previous products section
  ///
  /// In en, this message translates to:
  /// **'Previous Products'**
  String get previousProducts;

  /// Message when no products are available
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get noProductsAvailable;

  /// Title for product enquiries section
  ///
  /// In en, this message translates to:
  /// **'Product Enquiries'**
  String get productEnquirers;

  /// Customer service greeting message
  ///
  /// In en, this message translates to:
  /// **'How may I help you?'**
  String get howMayIHelpYou;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'ta': return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
