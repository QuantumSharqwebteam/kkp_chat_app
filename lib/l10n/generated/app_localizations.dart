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
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
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

  /// Label for new password input field
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
  /// **'We have sent the six digit verification code to'**
  String get verificationCodeSent;

  /// Error message for invalid verification code
  ///
  /// In en, this message translates to:
  /// **'Invalid code please try again'**
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
  /// **'By using KKP chat application, You agree to the'**
  String get privacyPolicyAgreement;

  /// Description of the app's purpose
  ///
  /// In en, this message translates to:
  /// **'A smart and efficient chat-based solution that connects customer with marketing agents in real time. Instantly manage inquiries, check stock availability, and track orders- all in one place. Empowering businesses with seamless communication and actionable insights.'**
  String get appDescription;

  /// Tagline for the app
  ///
  /// In en, this message translates to:
  /// **'Instant Inquiries,\nSeamless Sales.'**
  String get appTagline;

  /// Text for terms and privacy policy agreement
  ///
  /// In en, this message translates to:
  /// **'By using KKP chat application, you agree\nto the Terms and Privacy Policy'**
  String get termsAndPrivacyAgreement;

  ///
  ///
  /// In en, this message translates to:
  /// **'At KKP chat app, we respect your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, share, and safeguard your data when you use our chat application. By using our services, you agree to the terms outlined in this policy.\n\nThe collected data is used to provide seamless messaging services, enhance app security, analyze usage patterns, and improve customer support. Your messages are end-to-end encrypted to maintain confidentiality, and we implement security measures like secure cloud storage and restricted data access to protect your information. We do not sell or share your personal data with third-party advertisers. However, data may be shared with legal authorities if required by law or to prevent fraud and security threats.\n\nFor any questions or concerns regarding this Privacy Policy, you can contact us at support@kkpchatapp.com. By continuing to use KKP Chat App, you acknowledge and agree to the terms outlined in this policy.'**
  String get privacyPolicyFullText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
