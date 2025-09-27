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

  /// Label for user's full name input field
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

  /// Button or label text for adding a new product
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// Validation message shown when user leaves fields empty or incorrect
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields correctly!'**
  String get pleaseFillAllFields;

  /// Confirmation message shown when a product is added successfully
  ///
  /// In en, this message translates to:
  /// **'Product added successfully!'**
  String get productAddedSuccessfully;

  /// Button or label text for uploading a product image
  ///
  /// In en, this message translates to:
  /// **'Upload Product Image'**
  String get uploadProductImage;

  /// Button or label text for selecting a file
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// Label for the field where the user enters the product's name
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// Label for the field where the user enters their name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Label for the field where the user enters the product price
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Label for the field where the user selects or enters the product size
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// Label for the field where the user selects or enters the product color
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// Label indicating the quantity of product available in stock
  ///
  /// In en, this message translates to:
  /// **'Stock Available'**
  String get stockAvailable;

  /// Label for the field where the user enters the product description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Placeholder text for the product description input field
  ///
  /// In en, this message translates to:
  /// **'Describe about the product.......'**
  String get describeProduct;

  /// Placeholder or prompt text for selecting a product color
  ///
  /// In en, this message translates to:
  /// **'Pick a Color'**
  String get pickColor;

  /// Text for cancel button or action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Text for select button or dropdown option
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Label or button text for updating a form
  ///
  /// In en, this message translates to:
  /// **'Update Form'**
  String get updateForm;

  /// Prompt or label asking the user to fill product details
  ///
  /// In en, this message translates to:
  /// **'Fill Product Details'**
  String get fillProductDetails;

  /// Message shown when there are no customer forms available for navigation
  ///
  /// In en, this message translates to:
  /// **'No customer forms found to navigate to'**
  String get noCustomerForms;

  /// Message shown to confirm the order along with the form Id
  ///
  /// In en, this message translates to:
  /// **'Your order is confirmed with form Id'**
  String get orderConfirmed;

  /// Message shown when the order is declined along with the form Id
  ///
  /// In en, this message translates to:
  /// **'Your order is declined with form Id'**
  String get orderDeclined;

  /// Title for displaying the list of customers
  ///
  /// In en, this message translates to:
  /// **'Customers List'**
  String get customersList;

  /// Label or title for a user
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Label or title for a customer
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// Title or section label for customer inquiries
  ///
  /// In en, this message translates to:
  /// **'Customer Inquiries'**
  String get customerInquiries;

  /// Message or prompt shown when looking for the latest messages
  ///
  /// In en, this message translates to:
  /// **'Let\'s find latest messages'**
  String get findLatestMessages;

  /// Label or placeholder text for search functionality
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Label used when something (like a user or item) does not have a name
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get unnamed;

  /// Status label indicating a user is currently active or connected
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Title or label for the analytics management section
  ///
  /// In en, this message translates to:
  /// **'Analytics Management'**
  String get analyticsManagement;

  /// Confirmation message shown before downloading all data in Excel format
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to download all the data in excel format?'**
  String get confirmDownloadExcel;

  /// Text for confirm button or action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Message displayed when no activities are available
  ///
  /// In en, this message translates to:
  /// **'No activities found'**
  String get noActivitiesFound;

  /// Confirmation message shown before deleting all activities
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all activities?'**
  String get confirmDeleteAllActivities;

  /// Message shown when all data is deleted successfully
  ///
  /// In en, this message translates to:
  /// **'All data deleted successfully'**
  String get allDataDeletedSuccessfully;

  /// Message shown when deleting all data fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete all data'**
  String get failedToDeleteAllData;

  /// Text for editing a product
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// Text for updating a product
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get updateProduct;

  /// Label for pinned messages section
  ///
  /// In en, this message translates to:
  /// **'Pinned Messages'**
  String get pinnedMessages;

  /// Message shown when no agents are available
  ///
  /// In en, this message translates to:
  /// **'No agents found'**
  String get noAgentsFound;

  /// Prompt text shown to click and view chats
  ///
  /// In en, this message translates to:
  /// **'Click to see chats....'**
  String get clickToSeeChats;

  /// Label showing the available colors of a product
  ///
  /// In en, this message translates to:
  /// **'Available Colors:'**
  String get availableColors;

  /// Label indicating the product is out of stock
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// Label indicating how many items are left in stock
  ///
  /// In en, this message translates to:
  /// **'Left in Stock'**
  String get leftInStock;

  /// Label indicating limitation or exclusivity, e.g., 'Only 2 left'
  ///
  /// In en, this message translates to:
  /// **'Only'**
  String get only;

  /// Label indicating that a product or item is not available
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// Label or button text for editing an item or product
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Label or button text for removing an item or product
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Message shown when no products are available
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get noProductsAvailable;

  /// Message shown when no products match the search/filter criteria
  ///
  /// In en, this message translates to:
  /// **'No matching products found'**
  String get noMatchingProducts;

  /// Placeholder text for product search input field
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// Button or label text for uploading a new product
  ///
  /// In en, this message translates to:
  /// **'Upload new product'**
  String get uploadNewProduct;

  /// Prompt text for uploading a file or product
  ///
  /// In en, this message translates to:
  /// **'Upload here'**
  String get uploadHere;

  /// Label or text referring to a product
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// Label or title for notifications section
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Button or action to mark all notifications/messages as read
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// Label or title for user's account section
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// Confirmation message shown when user tries to log out
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirmLogout;

  /// Message shown when there are no customers available
  ///
  /// In en, this message translates to:
  /// **'No customers available'**
  String get noCustomersAvailable;

  /// Placeholder text for searching a customer
  ///
  /// In en, this message translates to:
  /// **'Search customer...'**
  String get searchCustomer;

  /// Label for manage action or button
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// Label for settings and activity section
  ///
  /// In en, this message translates to:
  /// **'Settings and Activity'**
  String get settingsAndActivity;

  /// Label for account section
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Label for account and security settings section
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get accountAndSecurity;

  /// Label describing account management and password change options
  ///
  /// In en, this message translates to:
  /// **'Account management, password change'**
  String get accountManagementPasswordChange;

  /// Label for management
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// Label for user management section
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// Label for viewing customer list
  ///
  /// In en, this message translates to:
  /// **'View customers'**
  String get viewCustomers;

  /// Label for managing analytics data
  ///
  /// In en, this message translates to:
  /// **'Manage Analytics Data'**
  String get manageAnalyticsData;

  /// Label for terms and policy section
  ///
  /// In en, this message translates to:
  /// **'Terms & Policy'**
  String get termsPolicy;

  /// Label for about section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Label for managing terms and policy section
  ///
  /// In en, this message translates to:
  /// **'Manage Terms & Policy'**
  String get manageTermsPolicy;
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
